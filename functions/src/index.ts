/* eslint-disable require-jsdoc */

import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";
import {
  HttpsError,
  onCall,
} from "firebase-functions/v2/https";
import * as ical from "node-ical";

initializeApp();

const db = getFirestore();

type ImportOptions = {
  importAssignments?: boolean;
  importQuizzes?: boolean;
  importOtherActivities?: boolean;
};

function cleanText(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }

  return value.trim();
}

function classifyEvent(
  title: string,
  description: string,
): string {
  const text =
      `${title} ${description}`.toLowerCase();

  if (
    text.includes("assignment") ||
    text.includes("submission") ||
    text.includes("coursework") ||
    text.includes("homework") ||
    text.includes("report")
  ) {
    return "Assignment";
  }

  if (
    text.includes("quiz") ||
    text.includes("test")
  ) {
    return "Quiz";
  }

  if (
    text.includes("exam") ||
    text.includes("midterm") ||
    text.includes("final examination") ||
    text.includes("end semester")
  ) {
    return "Exam";
  }

  if (
    text.includes("lecture") ||
    text.includes("lesson")
  ) {
    return "Lecture";
  }

  if (
    text.includes("lab") ||
    text.includes("practical")
  ) {
    return "Lab";
  }

  if (
    text.includes("project") ||
    text.includes("presentation")
  ) {
    return "Project";
  }

  return "Other";
}

function createEventId(
  sourceEventId: string,
): string {
  return `feels_${sourceEventId
    .replace(/[^a-zA-Z0-9_-]/g, "_")
    .slice(0, 100)}`;
}

function createAssignmentId(
  sourceEventId: string,
): string {
  return `feels_${sourceEventId
    .replace(/[^a-zA-Z0-9_-]/g, "_")
    .slice(0, 100)}`;
}

export const importFeelsCalendar = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (request) => {
    /*
     * Only authenticated UniFlow users can
     * import a FEELS calendar.
     */
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to import a calendar.",
      );
    }

    const uid = request.auth.uid;

    const calendarUrl = cleanText(
      request.data?.calendarUrl,
    );

    const options: ImportOptions =
      request.data?.options ?? {};

    if (!calendarUrl) {
      throw new HttpsError(
        "invalid-argument",
        "Calendar URL is required.",
      );
    }

    /*
     * Validate the URL before requesting it.
     */
    let parsedUrl: URL;

    try {
      parsedUrl = new URL(calendarUrl);
    } catch {
      throw new HttpsError(
        "invalid-argument",
        "Invalid calendar URL.",
      );
    }

    /*
     * Security:
     *
     * Only allow the official FEELS host.
     */
    if (
      parsedUrl.hostname !==
      "feels.pdn.ac.lk"
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Only FEELS calendar URLs are supported.",
      );
    }

    try {
      /*
       * Download the FEELS iCalendar feed.
       */
      const response = await fetch(
        calendarUrl,
      );

      if (!response.ok) {
        throw new Error(
          `FEELS returned HTTP ${response.status}.`,
        );
      }

      const icsText =
        await response.text();

      /*
       * Make sure the response is actually
       * an iCalendar file.
       */
      if (
        !icsText.includes(
          "BEGIN:VCALENDAR",
        )
      ) {
        throw new Error(
          "The FEELS response is not a valid iCalendar feed.",
        );
      }

      /*
       * Parse the .ics file.
       */
      const parsed =
        ical.parseICS(icsText);

      const userRef = db
        .collection("users")
        .doc(uid);

      const eventsRef =
        userRef.collection(
          "calendar_events",
        );

      const assignmentsRef =
        userRef.collection(
          "assignments",
        );

      const sourceRef =
        userRef
          .collection("calendar_sources")
          .doc("moodle");

      /*
       * Store the authenticated calendar URL
       * only on the backend-protected collection.
       *
       * Firestore rules should deny Flutter access
       * to calendar_credentials.
       */
      await userRef
        .collection(
          "calendar_credentials",
        )
        .doc("moodle")
        .set(
          {
            calendarUrl,
            updatedAt:
                  FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          },
        );

      /*
       * Update the visible calendar source.
       */
      await sourceRef.set(
        {
          name: "FEELS Calendar",
          type: "moodle",
          enabled: true,
          lastSyncedAt:
              FieldValue.serverTimestamp(),
          updatedAt:
              FieldValue.serverTimestamp(),
        },
        {
          merge: true,
        },
      );

      let imported = 0;
      let assignmentsImported = 0;
      let quizzesImported = 0;
      let otherImported = 0;

      /*
       * Process every VEVENT.
       */
      for (const key of Object.keys(
        parsed,
      )) {
        const item = parsed[key];

        if (
          !item ||
          item.type !== "VEVENT"
        ) {
          continue;
        }

        const event =
            item as ical.VEvent;

        /*
         * FEELS/Moodle event ID.
         */
        const sourceEventId =
            cleanText(event.uid) ||
            key;

        /*
         * Event title.
         */
        const title =
            cleanText(event.summary) ||
            "Untitled event";

        /*
         * Event description.
         */
        const description =
            cleanText(event.description);

        /*
         * Event location.
         */
        const location =
            cleanText(event.location);

        /*
         * Start date.
         */
        const start = event.start instanceof Date ?
          event.start :
          new Date(event.start);

        /*
         * Some calendar events may not have
         * an end date.
         *
         * We skip those events rather than
         * causing the Cloud Function to fail.
         */
        if (!event.end) {
          continue;
        }

        /*
         * End date.
         */
        const end = event.end instanceof Date ?
          event.end :
          new Date(event.end);

        /*
         * Validate both dates.
         */
        if (
          Number.isNaN(
            start.getTime(),
          ) ||
          Number.isNaN(
            end.getTime(),
          )
        ) {
          continue;
        }

        /*
         * Determine the academic event type.
         */
        const type =
            classifyEvent(
              title,
              description,
            );

        /*
         * Stable ID means re-importing the
         * same FEELS event updates it instead
         * of creating duplicates.
         */
        const eventId =
            createEventId(
              sourceEventId,
            );

        /*
         * Save the event to Calendar.
         */
        await eventsRef
          .doc(eventId)
          .set(
            {
              title,
              description,
              course: "",
              type,
              startTime: start,
              endTime: end,
              location,
              source: "moodle",
              sourceEventId,
              updatedAt:
                    FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            },
          );

        imported++;

        /*
         * Automatically create/update a task
         * when the FEELS event is an assignment.
         */
        if (
          type === "Assignment" &&
          options.importAssignments !== false
        ) {
          const assignmentId =
              createAssignmentId(
                sourceEventId,
              );

          await assignmentsRef
            .doc(assignmentId)
            .set(
              {
                title,
                course: "",
                description,

                /*
                   * The end date from the
                   * calendar becomes the
                   * assignment due date.
                   */
                dueDate: end,

                status: "Pending",
                priority: "Medium",
                progress: 0,

                /*
                   * These fields allow us to
                   * identify the task as coming
                   * from FEELS.
                   */
                source: "moodle",
                sourceEventId,
                calendarEventId: eventId,

                updatedAt:
                      FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              },
            );

          assignmentsImported++;

          continue;
        }

        /*
         * Count quizzes.
         */
        if (
          type === "Quiz" &&
          options.importQuizzes !== false
        ) {
          quizzesImported++;

          continue;
        }

        /*
         * Count other academic activities.
         */
        if (
          options.importOtherActivities !== false
        ) {
          otherImported++;
        }
      }

      /*
       * Send synchronization statistics
       * back to the Flutter application.
       */
      return {
        success: true,
        imported,
        assignmentsImported,
        quizzesImported,
        otherImported,
      };
    } catch (error) {
      console.error(
        "FEELS calendar import failed:",
        error,
      );

      throw new HttpsError(
        "internal",
        error instanceof Error ?
          error.message :
          "Unable to import FEELS calendar.",
      );
    }
  },
);
