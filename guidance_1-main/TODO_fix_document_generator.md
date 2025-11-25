# TODO: Fix backend/lib/document_generator.dart

## Issues Identified
- Uses Flutter-specific code (rootBundle, Syncfusion Flutter PDF) in pure Dart backend
- Incompatible with backend environment (Shelf server)
- Attempts to edit existing PDF template, but pdf package is better for generating from scratch

## Plan
- [ ] Rewrite generateGoodMoralCertificate to generate PDF from scratch using pdf package
- [ ] Remove Flutter dependencies (rootBundle, Syncfusion)
- [ ] Adapt for backend: save to 'documents' directory, no mobile permissions
- [ ] Use similar structure to lib/document_generator.dart but backend-compatible
- [ ] Test integration with routes that call it

## Implementation Steps
1. Update imports: remove flutter/services, syncfusion_flutter_pdf; add pdf, pdf/widgets
2. Rewrite generateGoodMoralCertificate method to build PDF using pw.Document
3. Include all necessary fields: studentName, course, schoolYear, purpose, gor, date
4. Save to documents directory (create if needed)
5. Return file path as before
6. Update pubspec.yaml if needed (add pdf if not present)
7. Test that routes can call it successfully
