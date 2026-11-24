---
title: Privacy
description: What the site counts about a visit, and what it does not keep.
---

The site counts its visits to learn which pages and components people use.
It does so with [Umami](https://umami.is), an open-source tool that runs on
the project's own server, so no third party receives the visits.

## What is counted

- The page you open, and the page or site that sent you there.
- Your browser, operating system, kind of device, screen size and language.
- Your approximate location, by country, region and city, worked out from
  your IP address when the visit arrives.

## What is not kept

- **No cookies.** Nothing is stored in your browser, so there is no banner
  to accept.
- **No personal data.** Your IP address is never stored. Visits from the
  same browser are grouped by an identifier made from that address, your
  browser and a secret of the server, mixed with a salt that changes every
  month, so they cannot be followed from one month to the next.
- Nothing is sold or shared, and no advertising network sees the visits.

## What collects nothing

- The components and the Showcase app. Copying a component into your app
  adds no analytics.
- Local builds of the site and `make docs-dev`.

A content blocker may stop the counting. The site works the same without it.
