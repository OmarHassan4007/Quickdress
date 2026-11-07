# Milestone 1 (revised): Scoping, Requirements and Architecture

This folder is the revised version of Milestone 1. It answers the instructor's comments on the first submission. The original submission is unchanged in [`../Milestone 1`](../Milestone%201).

## What changed

| Comment | What we changed |
|---|---|
| A layered architecture is too simple for our app. | The app is now a microkernel (plug-in) architecture: a Foundation-only core with a plug-in registry and an event bus, and plug-ins for capture, storage, context, filters and recommenders. Outfit generation is a pipe-and-filter pipeline. MVVM stays for the screens. The component, sequence and class diagrams were redrawn, and the deck's architecture slides were rebuilt. |
| We make statements we don't support with concrete plans. | The recommendation rules, thresholds and keyword list are written out. Every non-functional requirement has a test with a sprint, a tool and a pass mark. Each sprint has exit criteria, stretch goals follow a fixed rule, and every risk has a decision point. The wrong competitor comparison was corrected with sources, the unmeasured "10 minutes to 10 seconds" claim was removed, and Core ML was dropped from this term's plan. |

Each specification starts with a short "What changed in this revision" note.

## Files

Each document is provided as a Word file and as a PDF.

| File | What it is |
|---|---|
| `Milestone 1.docx` / `.pdf` | The full submission in one document: cover and links, Part A (Requirements Specification), Part B (Design Specification) and Part C (presentation outline) |
| `Quickdress_Requirements_Specification.docx` / `.pdf` | System overview, users and stakeholders, product backlog, scope and sprint plan, use cases, global and social considerations, and references |
| `Quickdress_Design_Specification.docx` / `.pdf` | Microkernel architecture, plug-in contracts and plug-ins, events, sequence diagrams, recommendation rules, quality attributes with a test plan, patterns, class diagram, build order with exit criteria, and risks |
| `Quickdress_Milestone1_Presentation.pptx` / `.pdf` | The 17-slide deck with speaker notes, revised for the new architecture |
| `Script_Slides_9-11.md` | Spoken script for slides 9 to 11 |

## Diagrams

| File | Used in |
|---|---|
| [`diagrams/component_diagram.png`](diagrams/component_diagram.png) | Design Specification, Figure 1 |
| [`diagrams/sequence_view_todays_outfit.png`](diagrams/sequence_view_todays_outfit.png) | Design Specification, Figure 2 |
| [`diagrams/sequence_produce_outfit.png`](diagrams/sequence_produce_outfit.png) | Design Specification, Figure 3 |
| [`diagrams/class_diagram.png`](diagrams/class_diagram.png) | Design Specification, Figure 4 |
| [`diagrams/sprint_plan.png`](diagrams/sprint_plan.png) | Requirements Specification, Figure 1 |
| [`diagrams/use_case_diagram.png`](diagrams/use_case_diagram.png) | Requirements Specification, Figure 2 |

## Links

- Jira: https://swe-quickdress-project.atlassian.net
