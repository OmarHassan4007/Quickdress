# Milestone 2: Sprint 1

Sprint 1 built a working digital wardrobe:

- adding clothes from the camera or the photo library
- storing their details
- editing and deleting them
- browsing them in a grid filtered by category, colour, season and ratings

It also delivered two items ahead of plan: an on-device cut-out and automatic suggestions (FR-13 and FR-17).

Each document is provided as a Word file and as a PDF.

## Files

| File | What it is |
|---|---|
| `Milestone 2.docx` / `.pdf` | The Sprint 1 report. It covers the sprint backlog, development and demo with screenshots, architecture and lower-level design changes, testing (methodology, 22 test cases, results and defects), the retrospective, and the documentation updates. |
| `Quickdress_Requirements_Specification.docx` / `.pdf` | Requirements Specification, revision 2, with a change log. |
| `Quickdress_Design_Specification.docx` / `.pdf` | Design Specification, revision 2, with a change log. The new section 7 is the lower-level design as built in Sprint 1. |
| `Presentation/Quickdress_Milestone2_Presentation.pdf` / `.pptx` | The 17-slide Milestone 2 deck. The .pptx has one image per slide and speaker notes. `Presentation/deck.html` is the source: open it in a browser to present, and the DONE stamps land as each slide comes into view. |
| `Test results/` | Logs of the automated test runs: three Swift packages, plus the app's unit and UI tests. |
| `diagrams/` | The new and updated figures, as images. `component3.png` is the component diagram with Sprint 1 status, `class3.png` the class diagram of the built code, `seq_add.png` and `seq_edit.png` the sequence diagrams for adding, editing and deleting an item, and `sprints2.png` the sprint plan. |

## How changes are tracked

Each specification starts with a change log that lists every revision: date, sections, what changed and why. In the body, two things mark what is new or changed in revision 2:

- rows shaded yellow
- paragraphs that start with **Changed in rev. 2**

The earlier revisions stay in the repository:

| Revision | Date | Folder |
|---|---|---|
| 0 | October 13, 2026 | [`../Milestone 1`](../Milestone%201) |
| 1 | November 5, 2026 (microkernel architecture) | [`../Milestone 1 (revised)`](../Milestone%201%20(revised)) |
| 2 | November 7, 2026 (after Sprint 1) | this folder |

## Test totals

82 automated tests, 0 failures:

| Suite | Tests |
|---|---|
| Core | 40 |
| Storage | 14 |
| Capture | 7 |
| App view models | 17 |
| End-to-end UI | 4 |

The 7 manual test cases are listed in the report.

## Screenshots

The app screenshots are in [`../Design/App screenshots`](../Design/App%20screenshots). `00-overview.png` shows all 15 screens.

## Links

- GitHub: https://github.com/OmarHassan4007/Quickdress
- Jira: https://swe-quickdress-project.atlassian.net
