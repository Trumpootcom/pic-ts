# PIC Tool Suite TODO

## File Format / Document System

* [ ] Implement `.picts` document file format support
* [ ] Add "Save As" flow for template-based `.picts` documents
* [ ] Separate project vs document loading logic
* [ ] Add reusable document/template serialization classes
* [ ] Add document metadata/version schema for future compatibility
* [ ] Add embedded undo history support to the `.picts` document format
* [X] Add ZIP-based project/document packaging system

---

## Templates

* [ ] Add export/import/share workflow for templates
* [ ] Add email/share/open integration for `.picts` files
* [ ] Add photo template profile-picture placement variants by roster count
* [X] Ensure templates initialize with empty `data/photos` and blank roster

---

## Android Integration

* [ ] Register `.picts` file association on Android
* [ ] Add "Open With PIC Tool Suite" Android intent handling
* [ ] Restore lost Android app project data handling strategy

---

## Compatibility Testing

* [ ] Test on newer Android versions
* [ ] Test on older Android versions
* [ ] Test on newer iPhone/iOS versions
* [ ] Test on older iPhone/iOS versions

---

## Project Browser / Document Workflow

* [ ] Create in-memory document open/import workflow
* [ ] In the project/document view, add sorting by:
  * Recent modified date
  * Alphabetical order
  * Graduation date
* [ ] Add project auto-save/version backup system
* [X] Add user-facing undo/redo history for document edits

---

## Photo Crop / Image Pipeline

* [ ] Add Capture directly from Camera
* [ ] Add Crop Guide overlay to Camera preview during capture (toggle guide?)
* [ ] Add visual crop-debug overlay/export mode
* [ ] Add toggle to switch crop guide shape between rectangle and oval
* [X] Add public/exported image gallery access outside app
* [X] Define long-term storage structure for embedded photos/assets
* [X] Finalize cropped-photo persistent storage location
* [X] Verify crop save matches exact visual transform (zoom/pan/rotate)
* [X] Decide between transformed-render save vs raw-source crop reconstruction

---

## Roster Layout / Class Photo Features

* [ ] Add student-name font size setting to portrait areas
* [ ] Add vertical name gap setting below ovals
* [ ] When adding a new roster entry, auto-scroll to the top so the new entry is immediately visible
* [ ] Automatically alphabetize students by last name when adding them to the roster
* [X] Update student paging arrows to increment by page size instead of 1
* [X] Only show "STUDENTS" label when `maxRosterPage > 1`
* [X] When adding a new roster entry, insert it at the beginning of the list

---

## PDF / Export System

* [ ] Add PDF editable-field/template investigation
* [ ] Choose clearer export icon for template preview pages
* [X] Continue PDF optimization work to avoid duplicated assets
* [X] Ensure PDF printing honors landscape orientation by default

---

## Template Preview UX

* [ ] Add pinch zoom to template preview
* [ ] Extract shared template layout engine for preview and PDF export
* [ ] Replace template preview page buttons with vertically scrollable/swipeable generated pages

---

## Architecture / Refactor

* [ ] Continue Flutter app file refactor from single-file architecture
* [X] Extract remaining UI/widgets from `main.dart`
* [X] Extract Projects carousel page into its own widget
* [X] Remove legacy `ProjectBrowserPage` after project workflow migration

---

## UI Chrome / Visual Design

* [ ] Replace default Material dialog accent colors with TSTS theme colors
* [X] Continue TSTS workspace/titlebar UI refactor
* [X] Replace roster delete X buttons with `delete_forever` trash can icons

---

## Workspace Navigation

* [ ] Split project workspace into:
  * Document Data page
  * Roster Data page
  * Render / Preview page
* [ ] Support circular page navigation
  * Last page wraps to first
  * First page wraps to last
* [ ] Center item in filmstrip is always selected
* [ ] Dim non-selected filmstrip items
* [ ] Support dragging the filmstrip to navigate pages
* [ ] Show partial adjacent pages during page transitions
* [ ] Restyle bottom navigator with a black filmstrip outline
* [X] Replace Projects filmstrip folder thumbnail with a custom project-list icon
* [X] Hide filmstrip when the workspace has only one page
* [X] Create bottom-mounted filmstrip navigator
* [X] Synchronize page carousel and filmstrip navigation
* [X] Animate filmstrip movement when selecting pages
* [X] Animate workspace pages in sync with filmstrip movement
* [X] Use template preview thumbnails as filmstrip items
* [X] Create Document icon for filmstrip
* [X] Create Roster icon for filmstrip
* [X] Keep action buttons in the top subtitle bar
* [X] Reserve bottom area exclusively for navigation
