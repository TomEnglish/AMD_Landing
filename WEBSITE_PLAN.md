# AMD Insight Website Plan

**URL:** https://amd.157.173.212.208.sslip.io  
**Created:** 2026-02-02  
**Status:** In Progress

---

## Current Pages (Done)

| Page | Description | Status |
|------|-------------|--------|
| `index.html` | Landing page, hero, book pitch, features | ✅ Done |
| `book.html` | Full book content (readable online) | ✅ Done |
| `references.html` | Scientific citations from the book | ✅ Done |
| `reading.html` | Related reading / further resources | ✅ Done |
| `about.html` | About the author + haiku | ✅ Done |
| `audiobook.html` | Audiobook player page | ⏳ Placeholder (audio in progress) |
| `newsletter.html` | Email signup | ✅ Done |

---

## Planned Pages (To Build)

### 1. Research Voting Page
**File:** `research.html` or `vote.html`

**Concept:** Let readers vote on research topics/interventions for future book updates or deep dives.

**Features:**
- [ ] List of potential research topics / interventions
- [ ] Upvote mechanism (simple, no login required?)
- [ ] Show vote counts
- [ ] Maybe categories: Supplements, Devices, Lifestyle, Emerging
- [ ] "Suggest a topic" form

**Implementation:** Lightweight backend (Supabase or Firebase)
- Anonymous voting (no login)
- Real vote counts stored in DB
- Simple API calls from frontend

---

### 2. AMD University
**File:** `university.html`

**Concept:** Curated video/audio learning hub — the "syllabus" for understanding AMD metabolically.

**Content:**
- [ ] Curated YouTube videos (metabolic health, vision, relevant science)
- [ ] NotebookLM audio content (AI-generated podcast-style discussions of book chapters)
- [ ] Organized by topic/module
- [ ] Brief descriptions of why each resource matters
- [ ] Difficulty levels: Intro → Intermediate → Deep Dive

**Modules to consider:**
- Module 1: Metabolic Health Foundations
- Module 2: Retinal Biology & Why It Matters
- Module 3: Photobiomodulation (Red Light)
- Module 4: Nutrition — DHA, Omega-3s, Seed Oils
- Module 5: CO₂, Breathing & Blood Flow
- Module 6: Related Conditions (CVD, Diabetes)
- Module 7: Practical Protocols

**NotebookLM ideas:**
- Chapter summaries as "podcast episodes"
- Q&A style discussions
- Deep dives on specific interventions

---

### 3. Related Reading & Resources (Expand Existing)
**File:** `reading.html` (expand)

**Currently has:**
- ✅ 5 essential books
- ✅ 6 key researchers
- ✅ 2 online resources

**Add:**
- [ ] Podcasts (metabolic health, vision, longevity)
- [ ] Communities / support groups (AMD forums, Reddit, Facebook groups)
- [ ] Supplement sources (trusted brands)
- [ ] Device recommendations (PBM devices, blue blockers)
- [ ] Practitioner directories (functional medicine, integrative ophthalmology)
- [ ] More websites/blogs worth following

---

## Audiobook Page Updates (When Ready)

- [ ] Embed audio player (HTML5 or podcast embed)
- [ ] Chapter navigation / timestamps
- [ ] Download links (M4B + MP3 zip)
- [ ] Sample preview clip
- [ ] Optional: Gumroad/Stripe for paid version or donations

---

## Site-Wide Improvements

- [ ] Real Amazon link on index.html (currently placeholder `#`)
- [ ] Favicon
- [ ] Open Graph meta tags (for social sharing previews)
- [ ] Copyright year: 2025 → 2026
- [ ] Domain: buy real domain later (noted in memory)

---

## Tech Notes

- Static HTML/CSS (no framework)
- Hosted at `/var/www/amd-book/`
- Served via Caddy reverse proxy
- Design: dark teal (#1a2f3a) + gold (#d4b896)
- Fonts: Cormorant Garamond (headings), Inter (body)

---

*Last updated: 2026-02-02*
