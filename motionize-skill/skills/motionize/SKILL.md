---
name: motionize
description: Turn a project directory or a website URL into a short, shareable launch video with music, motion, and share copy. One file, no bundled assets — built entirely by the model with the tools already on the machine. Use when someone says "/motionize", "motionize this", "make a launch video", or wants to show off what they built.
---

# /motionize

Turn what you built into a launch video. You make the whole video yourself — story, visuals, audio, render — with whatever tools are on the machine.

Whatever the tone, it should feel like a modern, slick, high-energy launch video. It is never a simple motion-graphic slideshow: something is always moving, the camera is always travelling, the frame is always rich with real assets, and the soundtrack drives it forward. Nothing on screen or in the soundtrack should be filler, but nothing should be static either.

Usage: `/motionize [input] [options]`. Options (flags or plain language):

| Option | Default |
|---|---|
| `--tone <preset or freeform>` | inferred; `default` if nothing clearly fits |
| `--format landscape\|vertical\|square` | landscape (1920×1080; vertical 1080×1920, square 1080×1080), 30fps |
| `--duration <s>` | about 20s |

Write the deliverables to `motionize-output/` in the current directory (timestamped `motionize-output-YYYY-MM-DD-HHmmss/` if it already exists). Keep every intermediate file (frames, downloads, scripts, stems) in a `work/` subfolder inside it.

## 1. Inspect

First decide what the input is, then gather material from it. Only the source changes; everything from the questions below onward is the same for every input.

| Input | How to recognize it | Where the material comes from |
|---|---|---|
| Project | No input given, and the current directory is a project | The code |
| Website | An `http(s)://` URL, or a bare domain like `example.com` | The live site |

If the input matches no type, or there's no input and the current directory isn't a project, ask the user what to make the video about.

### Project

Read the code: the main page, styles (exact colors and fonts), README, routes and key components. The best material is the product **in use** — find its 2–3 beats: entry → key action → result.

You have the source, so use it directly: import or render the project's real components, stylesheets, fonts, images and animations in the video instead of rebuilding them.

### Website

Get the site as a visitor sees it. Many sites build their page with JavaScript, so a plain download can come back as an almost empty shell. If it does, load the page in a headless browser to get the rendered result. Dismiss cookie banners and other overlays, and scroll section by section, since content that animates in on scroll stays blank in a single full-page capture.

- **Copy:** headline, tagline, section headings, feature names, calls to action, testimonials. Also check the title, meta description and social-preview tags.
- **Identity:** exact colors from the site's CSS and the fonts it loads.
- **Visuals:** the logo, product screenshots, hero images, demo videos. Download the ones you'll use into `work/`.
- **Screenshots:** capture the page at the video's aspect ratio to understand the layout. In the video, reuse the site's real markup, CSS and assets and animate those, rather than panning over flat screenshots.
- **The product in use:** check the demo videos, how-it-works sections and linked docs for the entry → key action → result flow.

### Then, for every input

Before planning, answer: What is it (one sentence)? Who is it for, and what does it do for them? What sets it apart? What's the most impressive or funniest claim? What's the visual hook? What real UI or flow should be shown? What tone fits? What's the one-line share caption?

## 2. Plan

Write `motionize-plan.md`: the angle, the hook, 2–3 highlights, the punchline, tone, visual identity, and a scene-by-scene storyboard with durations that sum to the target.

If the user points at one part — a new version, a new feature, one angle — make this the focus of the video.

The plan must also cover, for every scene: the **assets** on screen (real UI, logos, screenshots, product shots, icons, 3D or illustrated elements, particles, textures), the **animations** (what enters, moves, reacts, exits, and when), the **camera move** (see below), and the **beat** in the music it lands on. A scene with no camera move, fewer than three animated elements, or only text on a flat background is not finished; redesign it.

**Shape:** Hook (2–3s) → Reveal (2–4s) → 2–3 sharp highlights → Punchline/outro (2–4s). A starting shape, not a template.

## Creative laws

- **Short.** 15–25 seconds; 18–22 is the sweet spot.
- **Clear to a stranger.** After one viewing, someone who's never heard of it knows what it does, who it's for, and how to get it. Lead with that, not with how it's built.
- **The hook is everything.** The first 2 seconds decide whether anyone keeps watching. Plan it first.
- **Show the thing.** Reuse the real thing from the source — its UI, components, copy, images, videos and animations — rather than re-creating it. Rebuild only what you can't reuse. Prefer the working app doing its job over a landing page describing it. Small illustrative UI text is fine when showing the product in use (a filename, an "Exported" toast); invented claims, numbers, or testimonials are not. Never abstract filler.
- **Specific.** It must feel made for this exact project. Use its own copy and claims; no generic SaaS language ("streamline your workflow" is banned).
- **Readable.** Pace comes from motion and cuts, not from pulling text away early. Any line the viewer is meant to read stays fully visible and settled long enough to read it (roughly 0.3s per word), counted from when the whole line is on screen. Text that's only texture doesn't need to be read.
- **Never simple.** No flat title cards, no text sitting on a plain background, no lone element on an empty frame. Every moment layers a background, a hero asset, supporting assets and motion accents (parallax layers, floating UI, particles, light sweeps, shapes, lines, glows) so the frame always feels full and expensive.
- **Always in motion.** At no point is the whole frame still. Elements enter with staggered, eased motion (springs, overshoot, masks, wipes, scale and blur-ins), keep drifting or reacting while they hold, and exit with intent. Use simulated clicks, swipes, typing, counters and cursors for the product in use. Cut or transition at least every 1.5–3 seconds.
- **The camera always moves.** Treat every scene as a 3D or 2.5D stage with a virtual camera that is never locked off: push-ins, pull-backs, orbits and arcs around the product or hero asset, tilts, pans, dolly moves, parallax between depth layers, whip pans and zoom-throughs between scenes. Vary the move from scene to scene, ease it, and keep it motivated by what the viewer should look at. Moves can combine (an orbit with a slow push-in) but are never absent.
- **Plenty of assets.** Pull in as many real assets from the source as are useful: logo, UI components, screens, product imagery, icons, fonts, brand colors, video. Show the product from several angles and at several scales (wide, medium, macro close-up of a detail). Add generated or drawn supporting elements to fill depth. Reusing the real thing still beats re-creating it.
- **Energetic.** Pace, motion and sound all carry high energy. Land motion on the beat, build to the punchline, and end on a strong final move, not a fade to a static card.
- **Funny earns its place.** Humor comes from the project's own absurdity, not from trying.
- **Every frame postable.** Any frozen frame should be worth sharing.

## Motion library

Starting points, not a menu: mix, combine and invent. Pick a few that suit the project and its palette, and make each one specific to the project, never generic.

- **Shape-grid transitions.** Fill the frame with a grid of square tiles (about 12×7 or denser), each holding a bold geometric shape: circle, ring, dot cluster (2×2, dice-style fives), half and quarter circles, triangles. Use 4–5 flat brand colors, plus black and off-white. Tiles flip, rotate, scale and morph from one shape to the next in a ripple (diagonal, radial or random stagger) with a touch of motion blur, locked to the beat. Use it as a scene transition, or reveal the next scene by letting tiles flip over to show it. Tint the palette from the project's brand colors.
- **Bottom-to-top wipes.** The next scene rises from the bottom edge: a solid or patterned panel sweeps up with eased speed while the old scene lifts away slightly (parallax), or the new scene's content slides up inside a mask. Stagger bars or tiles for a curtain feel. Also works top-down, or sideways for variety.
- **Space and depth motion.** Fly the camera through a field of stars, dust and floating assets, with layers at different depths moving at different speeds. Push through a tunnel of UI cards or rings, orbit a floating product with a slow drift, or pull back from a macro detail out to a whole galaxy of the product's screens.
- **Particles.** Bursts and trails that react to the action: sparks on a click, confetti or shards on a reveal, dust and glow motes drifting through light beams, particles that assemble into the logo or a headline, then scatter on the beat. Colors come from the project's palette.
- **Product camera moves.** Orbit a product shot or UI card in 3D with perspective tilt, push in from wide to a macro close-up, rack focus between foreground and background layers, and whip-pan or zoom-through into the next scene.
- **Kinetic type.** Words slam, slide, scale and swap in tight sync with the beat, with a mask or wipe reveal for each word, never a plain fade. Keep readable lines fully settled long enough to read.
- **Pattern and texture backgrounds.** Moving grids, halftone dots, stripes, noise, light sweeps and gradients under every scene, so no background is ever flat.
- **HUD and frame details.** Small overlay details, such as corner brackets, a running timecode, a BPM or FPS readout, a section label and a progress bar, give the video a crafted, edit-suite feel. Use them lightly so they never cover the product.

## Tones

Presets are defaults; freeform direction ("fake Series A launch from 2016") refines or overrides them.

| Tone | Feel | Pacing / transitions |
|---|---|---|
| `default` | Punchy, playful, energetic | 5–7 scenes; camera-driven transitions, whip pans, zoom-throughs |
| `polished` | Elegant, confident, premium | 4–6 scenes; smooth orbits and dolly moves, parallax, light sweeps |
| `yc-parody` | Deadpan startup launch, played straight | 5–6 scenes, one claim each; hard cuts with fast push-ins |
| `chaotic` | FAST, LOUD, ALL CAPS | 7–10 scenes, some under 1.5s; flash/zoom cuts, shake, glitch |
| `deadpan` | Dry, nothing is a joke | 4–6 scenes; the delivery is dry but the camera and assets still move constantly |
| `cinematic` | Trailer-scale, epic claims | 5–7 scenes, big type; sweeping crane and orbit moves, dramatic wipes |
| `app-store` | Clean, bright feature showcase | 5–7 scenes; sliding cards with parallax and camera glides |

Every tone keeps the motion, camera and asset rules above. Tone changes the attitude, never the energy floor.

## Sound

Pick or write music with a driving, energetic pulse and build, then cut and animate to its beats. Write the music and sound effects as one piece: effects in the same key and the same space as the music, blended in rather than laid on top. Give it a basic, proper mix, the way a real track is mixed: effects sit softly under the music, nothing harsh or spiky, and repeated little sounds stay in the background.

## 3. Build, check, render

Build it with whatever works on this machine. If you draw the video in a browser, make every frame a pure function of time and wait for fonts and images to load before capturing each one.

Before the full render, check motion density: scrub the timeline and confirm that no stretch longer than about a second has a still frame, that every scene has a camera move, and that every scene has layered assets. Add motion or assets where it feels sparse.

Then look at stills from every scene *and* from mid-transition, and fix overflow, collisions, and low contrast. A plain crossfade between two busy layouts makes a muddy double exposure; stagger it (old content out, then new content in) or dip through the background. Then render `motionize.mp4`.

## 4. Deliver

- **Poster:** pull the strongest *settled* frame (text fully in, not mid-transition) to `motionize.jpg`, and bake it in as frame 0 of `motionize.mp4` so every platform's thumbnail shows it. Replace frame 0 rather than adding a frame, so the duration and audio sync stay the same.
- **`share-copy.txt`:** 1–3 sentences, postable as-is, specific, matching the tone. No "excited to share."
- **Tell the user** where the video and copy are, give one sentence on the creative angle, and offer to re-roll a scene or try another tone.
