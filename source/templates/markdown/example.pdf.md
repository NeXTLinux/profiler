# 📒 Markdown template example (pdf)

See [rendering of this file here](https://github.com/nextlinux/profiler/blob/examples/profiler.markdown.pdf) and [original template source here](https://github.com/nextlinux/profiler/blob/master/source/templates/markdown/example.pdf.md).

## 🧩 Plugins

All markdown features are supported, meaning that both markdown plugins and SVG renders can be used.

<%- await include(`partials/rss.ejs`) %>

<%- await embed(`example-isocalendar-pdf`, {isocalendar:true}) %>
