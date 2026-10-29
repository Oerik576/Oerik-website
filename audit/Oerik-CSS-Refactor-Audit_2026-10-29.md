# OERIK Website CSS Refactor Audit

**Date:** 2026-10-29  
**Source audited:** `Oerik-website_2026-10-29.zip`

## Purpose

Reduce the size and maintenance burden of `themes/oerik/assets/css/main.css` without redesigning the site or changing the established responsive behavior.

## Result

- Original `main.css`: **2,094 lines / 39,991 bytes**
- Refactored `main.css`: **24 lines / 962 bytes**
- Existing component files retained: `header.css`, `footer.css`, `player-portal.css`
- New component files created: **17**
- Total component stylesheets after refactor: **20**
- CSS parser errors after refactor: **0**
- Content image references checked: **111**
- Missing referenced images: **0**
- Duplicate featured-image/manual-hero pairs remaining: **0**

## Refactor Strategy

The original stylesheet was already organized into clearly labeled sections. Those sections were moved into component files in the **same source order** and imported by `main.css` in that same order. This preserves the existing CSS cascade while making each subsystem easier to maintain.

No broad visual redesign was performed. Existing selectors and declarations were retained unless noted below.

## New CSS Structure

`themes/oerik/assets/css/main.css` is now the stylesheet entry point and imports:

1. `components/header.css`
2. `components/footer.css`
3. `components/player-portal.css`
4. `components/base.css`
5. `components/homepage.css`
6. `components/standard-page.css`
7. `components/campaign-journal.css`
8. `components/dispatch-article.css`
9. `components/magazine.css`
10. `components/campaign-pages.css`
11. `components/responsive-core.css`
12. `components/campaign-character.css`
13. `components/game-rules.css`
14. `components/campaigns-landing.css`
15. `components/party-roster.css`
16. `components/greyhawk.css`
17. `components/campaign-resources.css`
18. `components/npc-directory.css`
19. `components/adventures.css`
20. `components/journal-roster.css`

## Reusable Dispatch Article Image Sizes

A generic image-size system was added to `components/dispatch-article.css`:

- `article-image--small` — up to 280px
- `article-image--medium` — up to 450px
- `article-image--large` — up to 700px
- `article-image--wide` — full article width

Example:

```html
{{< figure
    src="/images/articles/example/image.webp"
    alt="Description"
    class="article-image--small"
>}}
```

This replaces the need to create article-specific CSS rules simply to control image width.

## Joseph Bloch Article

`content/articles/creator-spotlight-joseph-bloch/index.md` was updated to use the reusable classes:

- Dragon Magazine #167 cover: `article-image--small`
- Greyhawk Grognard logo: `article-image--medium`
- BRW Games logo: `article-image--small`

The featured Joseph Bloch portrait remains controlled by the Dispatch layout and stays full width as the article hero.

## Duplicate Hero Images Removed

The Dispatch layout automatically renders `featured_image`. Three additional articles were found to manually insert the exact same image again. Those duplicate manual hero figures were removed from:

- `content/articles/through-the-pages-dragon-magazine-issue-1/index.md`
- `content/articles/the-referees-toolbox/index.md`
- `content/articles/from-the-archive-supplement-i-greyhawk/index.md`

The `featured_image` front matter remains unchanged in all three articles.

## Validation Performed

- Parsed every CSS file after refactoring: no parser errors found.
- Confirmed every component imported by `main.css` exists.
- Confirmed all 111 `/images/...` references found in Markdown content resolve to files under `static/images/`.
- Confirmed the Joseph Bloch supporting image files exist.
- Confirmed no article still inserts the same image both as `featured_image` and as a manual body figure.

## Build Validation Limitation

The audit environment does not have the Hugo executable installed, so a full Hugo render could not be run here. The refactor preserves the original CSS ordering, and the project already used CSS `@import` through Hugo's asset pipeline before this change.

After applying the patch locally, run the normal OERIK Hugo development server and visually check the homepage, one Dispatch article, one Storm Tide journal, the NPC directory, and the Adventures catalog before deployment.

## Future CSS Rule

When adding new features, add styles to the appropriate component file rather than `main.css`. `main.css` should remain an import-only entry point except for an exceptional sitewide requirement.
