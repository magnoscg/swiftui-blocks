---
title: Privacy
description: What the site counts about a visit, what it does not keep, and who else sees a visit.
---

The site counts its visits to learn which pages and components people use.
It does so with [Umami](https://umami.is), an open-source tool that runs on
the project's own server. The counts stay there: no analytics company
receives them, and they are not sold or shared.

## What is counted

- The address and title of the page you open, and the site that sent you
  there, both without the part after `?` or `#`.
- Your browser, operating system, kind of device, screen size and language.
- Your country, which Cloudflare works out from your IP address.

## What is not kept

- **No cookies.** The counting stores nothing in your browser. The site
  itself keeps there only the theme and the tabs you choose, and the
  repository's star count until you close the tab.
- **No IP address.** Umami does not store it. It groups your visits under an
  identifier made from that address, your browser and a secret of the
  server, which changes every month.
- Nothing that names you, such as an account or an email address.

## Who else sees a visit

- GitHub Pages serves the site, and Cloudflare carries the requests to the
  counter, as each does for any site it serves.
- The bar at the top asks GitHub for the repository's stars from your
  browser.

## What collects nothing

- The components and the Showcase app. Copying a component into your app
  adds no analytics.
- Local builds of the site and `make docs-dev`.

A content blocker may stop the counting. The site works the same without it.
