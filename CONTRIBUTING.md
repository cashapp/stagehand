### Sign the CLA

All contributors to your PR must sign our [Individual Contributor License Agreement (CLA)](https://spreadsheets.google.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1). The CLA is a short form that ensures that you are eligible to contribute.

### One Issue per Pull Request

Keep your Pull Requests small. Small PRs are easier to reason about which makes them significantly more likely to get merged.

### Issues Before Features

If you want to add a feature, please file an [Issue](https://github.com/CashApp/Stagehand/issues) first. An Issue gives us the opportunity to discuss the requirements and implications of a feature with you before you start writing code.

### Backwards Compatibility

Respect the minimum deployment target. If you are adding code that uses new APIs, make sure to prevent older clients from crashing or misbehaving. Our CI runs against our minimum deployment targets, so you will not get a green build unless your code is backwards compatible.

### Forwards Compatibility

Please do not write new code using deprecated APIs.

### Keep the Demo App and Documentation Updated

When adding new features or making changes to existing features, make sure to update the included demo app and tutorial playground so new users can understand what's available.
