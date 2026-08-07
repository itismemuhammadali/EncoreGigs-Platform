# Chat Feature Enhancements Plan

Implementation plan for adding File Attachments, Image Attachments, Emoji Pickers, Web Search Bar, User Profile Popups, and Role Badges (`[MUS]` / `[ORG]`) across the Musician App, Organizer App, and Web Admin Portal.

---

## User Review Required

> [!IMPORTANT]
> **Phased Workflow Execution**:
> 1. **Phase 1 (Immediate First Step)**: Admin Web Portal User Role Badge Format (`Name [MUS]` and `Name [ORG]`).
> 2. **Phase 2**: Musician App Chat Attachments (File Picker, Image Picker, Emoji Selector, Media Bubbles).
> 3. **Phase 3**: Organizer App Chat Attachments & Emojis (Full Feature Parity).
> 4. **Phase 4**: Web Admin Portal Enhancements (Search Bar by Name/Gmail, User Profile Details Popup Modal, File/Image Upload & Emojis).

---

## Proposed Changes

### Phase 1: Web Admin Portal User Role Badge Format (`[MUS]` / `[ORG]`)

#### [MODIFY] [backend/routers/support.py](file:///Users/muhammadali3000/development/onlygigz/backend/routers/support.py)
* Update chat summary endpoint to fetch user profile metadata (email, phone, role) and format user names or include distinct role indicators.

#### [MODIFY] [web/admin_portal/src/app/(dashboard)/messages/MessagesClient.tsx](file:///Users/muhammadali3000/development/onlygigz/web/admin_portal/src/app/(dashboard)/messages/MessagesClient.tsx)
* Append `[MUS]` bracket after Musician names and `[ORG]` bracket after Organizer names in the chat sidebar list and active chat header.

---

### Phase 2: Musician App Chat Attachments & Emojis (`apps/musician`)

#### [MODIFY] [apps/musician/lib/services/support_chat_service.dart](file:///Users/muhammadali3000/development/onlygigz/apps/musician/lib/services/support_chat_service.dart)
* Extend `SupportMessage` model to support `imageUrl` and `fileUrl` / `fileName` attachment properties.
* Add helper methods to upload picked files/images to Firebase Storage or backend media storage.

#### [MODIFY] [apps/musician/lib/screens/main/live_chat_screen.dart](file:///Users/muhammadali3000/development/onlygigz/apps/musician/lib/screens/main/live_chat_screen.dart)
* Wire **File Attachment Icon** (`attach_files_icon.svg`) using `file_picker` to send documents.
* Wire **Image Attachment Icon** (`image_icon.svg`) using `image_picker` / `file_picker` to upload and send photos.
* Wire **Emoji Icon** (`Icons.emoji_emotions_outlined`) to open an emoji picker bottom sheet.
* Render image previews and file download bubbles inside the message list.

---

### Phase 3: Organizer App Chat Attachments & Emojis (`apps/organizer`)

#### [MODIFY] [apps/organizer/lib/services/support_chat_service.dart](file:///Users/muhammadali3000/development/onlygigz/apps/organizer/lib/services/support_chat_service.dart)
* Sync model definitions for media attachment handling.

#### [MODIFY] [apps/organizer/lib/screens/profile/live_chat_screen.dart](file:///Users/muhammadali3000/development/onlygigz/apps/organizer/lib/screens/profile/live_chat_screen.dart)
* Wire file picker, image picker, emoji picker, and media bubble rendering for complete feature parity with Musician app.

---

### Phase 4: Web Admin Portal Search Bar, Profile Details Modal & Attachments

#### [MODIFY] [web/admin_portal/src/app/(dashboard)/messages/MessagesClient.tsx](file:///Users/muhammadali3000/development/onlygigz/web/admin_portal/src/app/(dashboard)/messages/MessagesClient.tsx)
1. **Search Bar**: Add search input filtering chats by **User Name** or **Email (Gmail)**.
2. **User Profile Popup Modal**:
   * Display profile avatar in chat list and header.
   * Make user header clickable to open a sleek pop-up modal displaying key registration details:
     * Full Name & Profile Image
     * Email Address
     * Phone Number
     * Role (`MUS` / `ORG`)
     * Signup / Joined Date
3. **Web Media Upload & Emojis**:
   * Add attachment buttons for image/file upload and emoji picker on web.
   * Render images and downloadable files in message bubbles.

---

## Verification Plan

### Manual Verification
1. **Phase 1 Verification**: Open `http://localhost:3000/messages` and verify user names show `[MUS]` or `[ORG]` in brackets.
2. **Phase 2 Verification**: Open Musician App -> Help & Support -> Live Chat. Pick an image and file, select emojis, send message, and verify media displays in chat.
3. **Phase 3 Verification**: Open Organizer App -> Help & Support -> Live Chat. Test sending files, images, and emojis.
4. **Phase 4 Verification**: Open Web Admin Portal -> Messages:
   * Test search bar with name and Gmail.
   * Click user header and verify profile popup details modal.
   * Verify attached images and files sent from mobile apps render and can be opened on web.
