# TODO: Reset Good Moral Request Flow

## Steps to Complete

- [x] Update lib/student/good_moral_request.dart:
  - [x] Change _validIdTypes to ['School ID'].
  - [x] Modify _validateData to strictly require signature (error if no signature).
  - [x] Add student type selection (grad/undergrad) at the beginning of the flow.
  - [x] Based on student type and whether they have ID, provide options:
    - [x] Option 1: OCR if have ID.
    - [x] Option 2: Manual input if no ID.
  - [x] For manual input, add text fields for name, address, signature.
  - [x] Update UI to reflect the new options and flow.
  - [x] Ensure submission works for both OCR and manual input.

- [ ] Test the new flow:
  - [ ] Verify OCR on school ID detects signature.
  - [ ] Check error for missing signature.
  - [ ] Test manual input submission.
  - [ ] Ensure backend handles the data correctly.

- [ ] If needed, update backend routes to handle manual input data.
