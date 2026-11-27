-- Pandoc filter. Typst runs with --root /, so image paths must be absolute.
-- Relative paths resolve against the build dir (mermaid output) first, then
-- the source dir. BUILD_DIR and SOURCE_DIR are prepended by render.py.
-- TODO: fetch remote images instead of dropping them to alt text.
function Image(img)
  if img.src:match("^%a+://") then return img.caption end
  if img.src:sub(1, 1) == "/" then return img end
  for _, dir in ipairs({BUILD_DIR, SOURCE_DIR}) do
    local path = dir .. "/" .. img.src
    if io.open(path) then img.src = path; return img end
  end
end
