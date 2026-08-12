Put any landing-page images in this folder.

Supported formats:
- .png
- .jpg
- .jpeg
- .webp
- .gif

After adding or removing images, run:
update-gallery.ps1

That will refresh gallery-manifest.js so the landing page shows the latest files automatically.

Faster option:
run refresh-landing-gallery.ps1

This updates the gallery manifest in one step and leaves the project ready for GitHub publishing.

One-click publish:
run publish-landing-gallery.ps1

This updates the gallery, saves the landing-page changes, and pushes them to GitHub.

It also publishes the current landing-page logo and cover image.
