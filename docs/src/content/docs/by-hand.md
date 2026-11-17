---
title: Add a component by hand
description: Find a component, copy its file and use it in your app, without an agent.
---

1. Find it in the [catalog](/catalog/) or with the search box.
2. Check its minimum iOS against the deployment target of your app.
3. On its page, press **Copy code** and paste it into a new Swift file in your
   app target, or press **Download .swift**. A component drawn by a Metal
   shader shows a second file: add it to the same target as `<Name>.metal`.
4. Use it. The `Demo` view and the `#Preview` at the end of the file show how,
   and you can delete them afterwards.

Keep the two lines at the top of each file: they are its license notice.
