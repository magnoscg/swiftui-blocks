---
title: Privacy
description: What the site counts about a visit, what it does not keep, and who else sees a visit.
---

The site counts its visits to learn which pages and components people use.
It does so with [Umami](https://umami.is), an open-source tool that runs on
the project's own server. No analytics company receives the counts, and
they are not sold or shared.

## What is counted

- The address and title of each page you open, and when you open it.
- The page that sent you there.
- Your browser, operating system, kind of device, screen size and language.
- Your country, which Cloudflare works out from your IP address.

Addresses are counted without the part after `?` or `#`.

## What is not kept

- **No cookies.** The counting stores nothing in your browser. The site
  itself keeps there your theme and the tabs you choose and, until you close
  the tab, the state of the sidebar and the repository's star count.
- **No IP address.** Umami does not store it. It groups your visits under an
  identifier made from that address, your browser and a secret of the
  server. The identifier changes every month.
- **No account.** The site has no sign-in and never asks your name or email
  address.

## Who else sees a visit

- GitHub serves the site through GitHub Pages, and your browser asks GitHub
  for the previews of the components and the repository's star count.
- Cloudflare carries the requests to the counter and keeps a daily backup of
  the counts.

## What collects nothing

- The components and the Showcase app. Copying a component into your app
  adds no analytics.
- Local builds of the site and `make docs-dev`.

A content blocker may stop the counting. The site works the same without it.
