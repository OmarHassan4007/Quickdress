# Quickdress: script for slides 9 to 11 (revised)

About 4 minutes at a calm pace (roughly 600 words). Revised for the microkernel architecture. Directions are in [brackets]; don't read them out.

---

## Slide 9: Twelve use cases, one person in charge (about 1:20)

[Slide 9 comes up. Point at the user on the left of the diagram.]

This is piece C, and we'll start with who uses Quickdress. There's one primary actor, and that's the user. Every one of the twelve use cases starts with them. They add, edit and browse their clothes. They view today's outfit, swap a piece they don't like, or ask for a completely new outfit. They set filters, mark an outfit as worn, and decide whether to turn on AI suggestions.

[Point at the three actors on the right.]

On the right are three secondary actors. These aren't people. They're systems the app calls. A weather service gives us the forecast. That's the free Open-Meteo service, or Apple WeatherKit if one of us gets a developer membership. The iOS Calendar gives us today's events. And Gemini is only used when the user has switched AI suggestions on and the phone is online. If either of those isn't true, Gemini is never contacted.

[Point at the highlighted use case.]

The highlighted use case is the main one: viewing today's outfit. It always includes getting the forecast and reading the calendar, because the outfit depends on both. But if the user says no to location or calendar access, the app doesn't break. It still finishes and picks an outfit using sensible defaults.

## Slide 10: Privacy comes first (about 1:30)

[Click to slide 10.]

Now the considerations we had to think about, and the biggest one is privacy. Think about what this app holds: photos of your clothes, where you are, and your calendar. Put those together and you can work out someone's whole routine. So all of it stays on the phone. There's one outside AI call, it's off by default, and even when it's on it never sends photos, calendar text or your location.

[Move down the list on the right.]

Culture matters too. What people wear depends on religion, workplace and family, so we don't guess that from fashion data. The user sets formality and comfort themselves. That means modest and hijab-friendly outfits work properly, and the app never scores how anyone looks.

For health and safety, dressing for the weather really matters in a Cairo summer, and not having to think about clothes takes some stress out of the morning.

For the environment, the app only suggests clothes you already own, so it pushes you to re-wear things instead of buying more.

On the economic side, it's free. No in-app purchases and no shopping links.

And for access, the app does the colour matching for you, which helps anyone who finds that hard. VoiceOver and Arabic support are planned.

That's piece C. [Pause.] Piece D is the design.

## Slide 11: How Quickdress is put together (about 1:20)

[Click to slide 11. Point at B, the core, first.]

Quickdress uses a microkernel architecture, which is also called a plug-in architecture.

B is the core. It's a small piece of plain Swift that holds the rules that don't change: the wardrobe manager, the context builder, the outfit engine, an event bus and the settings. It doesn't import anything from Apple except Foundation.

[Point at C.]

C is everything that can vary, and every part of it is a plug-in. Where photos come from, the camera or the photo library. Where data is stored. Where the weather and the calendar come from. The outfit filters. And the recommenders.

[Point at the red box.]

The red box is the plug-in registry. It picks the right plug-in at run time, by priority and by whether it's available. So if WeatherKit isn't available, the Open-Meteo plug-in is used, and nothing else in the app changes.

[Point at A.]

A is the screens. They follow MVVM, and they only ever talk to the core.

One honest detail: iOS doesn't let an app download new code, so our plug-ins are compiled into the app. What makes them plug-ins is that the core only knows their contracts, never the plug-ins themselves.

[Click to slide 12.]
