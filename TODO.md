# PIC Tool Suite TODO

## File Format / Document System

* [ ] Implement `.picts` document file format support
* [x] Add ZIP-based project/document packaging system
* [ ] Add "Save As" flow for template-based `.picts` documents
* [ ] Separate project vs document loading logic
* [ ] Add reusable document/template serialization classes
* [ ] Add document metadata/version schema for future compatibility
* [ ] Add embedded undo history support to the `.picts` document format

---

## Templates

* [ ] Ensure templates initialize with empty `data/photos` and blank roster
* [ ] Add export/import/share workflow for templates
* [ ] Add email/share/open integration for `.picts` files

---

## Android Integration

* [ ] Register `.picts` file association on Android
* [ ] Add "Open With PIC Tool Suite" Android intent handling
* [ ] Restore lost Android app project data handling strategy

---

## Project / Document UX

* [ ] Create in-memory document open/import workflow
* [ ] In the project/document view, add sorting by:

  * Recent modified date
  * Alphabetical order
  * Graduation date
* [ ] Add project auto-save/version backup system
* [ ] Add user-facing undo/redo history for document edits

---

## Photo Crop / Image Pipeline

* [ ] Finalize cropped-photo persistent storage location
* [x] Verify crop save matches exact visual transform (zoom/pan/rotate)
* [x] Decide between transformed-render save vs raw-source crop reconstruction
* [ ] Add visual crop-debug overlay/export mode
* [ ] Add public/exported image gallery access outside app
* [ ] Define long-term storage structure for embedded photos/assets
* [ ] Add toggle to switch crop guide shape between rectangle and oval

---

## Student Layout / Class Photo Features

* [ ] Add student-name font size setting to portrait areas
* [ ] Add vertical name gap setting below ovals
* [x] Update student paging arrows to increment by page size instead of 1
* [x] Only show "STUDENTS" label when `maxRosterPage > 1`
* [ ] When adding a new roster entry, insert it at the beginning of the list and auto-scroll to the top so the new entry is immediately visible
* [ ] Automatically alphabetize students by last name when adding them to the roster

---

## PDF / Export System

* [x] Continue PDF optimization work to avoid duplicated assets
* [ ] Add PDF editable-field/template investigation
* [x] Ensure PDF printing honors landscape orientation by default

---

## Flutter Refactor / Architecture

* [ ] Continue Flutter app file refactor from single-file architecture
* [ ] Extract remaining UI/widgets from `main.dart`

---

## UI / Visual Design

* [ ] Continue TSTS workspace/titlebar UI refactor
* [ ] Refine subtitle/action button vertical alignment
* [ ] Finalize title/subtitle/header scaling consistency
* [ ] Add cloudy repeating border to title bar B asset
* [ ] Build mathematically generated concave-up cloud-edge generator

---

## Workspace Navigation

* [ ] Split project workspace into:

  * Document Data page
  * Roster Data page
  * Render / Preview page

* [ ] Create bottom-mounted filmstrip navigator

* [ ] Synchronize page carousel and filmstrip navigation

* [ ] Support circular page navigation

  * Last page wraps to first
  * First page wraps to last

* [ ] Center item in filmstrip is always selected

* [ ] Dim non-selected filmstrip items

* [ ] Animate filmstrip movement when selecting pages

* [ ] Animate workspace pages in sync with filmstrip movement

* [ ] Support dragging the filmstrip to navigate pages

* [ ] Show partial adjacent pages during page transitions

* [ ] Use template preview thumbnails as filmstrip items

* [ ] Create Document icon for filmstrip

* [ ] Create Roster icon for filmstrip

* [ ] Keep action buttons in the top subtitle bar

* [ ] Reserve bottom area exclusively for navigation
