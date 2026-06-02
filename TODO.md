# PIC Tool Suite TODO

## File Format / Document System

* [ ] Implement `.picts` document file format support
* [ ] Add "Save As" flow for template-based `.picts` documents
* [ ] Separate project vs document loading logic
* [ ] Add reusable document/template serialization classes
* [ ] Add document metadata/version schema for future compatibility
* [ ] Add embedded undo history support to the `.picts` document format
* [x] Add ZIP-based project/document packaging system

---

## Templates

* [ ] Add export/import/share workflow for templates
* [ ] Add email/share/open integration for `.picts` files
* [ ] Add photo template profile-picture placement variants by roster count
* [x] Ensure templates initialize with empty `data/photos` and blank roster

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
* [x] Add user-facing undo/redo history for document edits

---

## Photo Crop / Image Pipeline

* [ ] Add visual crop-debug overlay/export mode
* [ ] Add toggle to switch crop guide shape between rectangle and oval
* [x] Add public/exported image gallery access outside app
* [x] Define long-term storage structure for embedded photos/assets
* [x] Finalize cropped-photo persistent storage location
* [x] Verify crop save matches exact visual transform (zoom/pan/rotate)
* [x] Decide between transformed-render save vs raw-source crop reconstruction

---

## Roster Layout / Class Photo Features

* [ ] Add student-name font size setting to portrait areas
* [ ] Add vertical name gap setting below ovals
* [ ] When adding a new roster entry, auto-scroll to the top so the new entry is immediately visible
* [ ] Automatically alphabetize students by last name when adding them to the roster
* [x] Update student paging arrows to increment by page size instead of 1
* [x] Only show "STUDENTS" label when `maxRosterPage > 1`
* [x] When adding a new roster entry, insert it at the beginning of the list

---

## PDF / Export System

* [ ] Add PDF editable-field/template investigation
* [ ] Choose clearer export icon for template preview pages
* [x] Continue PDF optimization work to avoid duplicated assets
* [x] Ensure PDF printing honors landscape orientation by default

---

## Template Preview UX

* [ ] Add pinch zoom to template preview
* [ ] Extract shared template layout engine for preview and PDF export
* [ ] Replace template preview page buttons with vertically scrollable/swipeable generated pages

---

## Architecture / Refactor

* [ ] Continue Flutter app file refactor from single-file architecture
* [x] Extract remaining UI/widgets from `main.dart`
* [x] Extract Projects carousel page into its own widget
* [x] Remove legacy `ProjectBrowserPage` after project workflow migration

---

## UI Chrome / Visual Design

* [ ] Replace default Material dialog accent colors with TSTS theme colors
* [x] Continue TSTS workspace/titlebar UI refactor

---

## Workspace Navigation

* [ ] Split project workspace into:
  * Document Data page
  * Roster Data page
  * Render / Preview page
* [ ] Replace Projects filmstrip folder thumbnail with a custom project-list icon
* [ ] Support circular page navigation
  * Last page wraps to first
  * First page wraps to last
* [ ] Center item in filmstrip is always selected
* [ ] Dim non-selected filmstrip items
* [ ] Support dragging the filmstrip to navigate pages
* [ ] Show partial adjacent pages during page transitions
* [ ] Restyle bottom navigator with a black filmstrip outline
* [x] Hide filmstrip when the workspace has only one page
* [x] Create bottom-mounted filmstrip navigator
* [x] Synchronize page carousel and filmstrip navigation
* [x] Animate filmstrip movement when selecting pages
* [x] Animate workspace pages in sync with filmstrip movement
* [x] Use template preview thumbnails as filmstrip items
* [x] Create Document icon for filmstrip
* [x] Create Roster icon for filmstrip
* [x] Keep action buttons in the top subtitle bar
* [x] Reserve bottom area exclusively for navigation
