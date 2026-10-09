# Third-Party Software Notices & Acknowledgments

This document contains licensing notices and copyright information for third-party open-source components and external technologies utilized, referenced, or dynamically interfaced with by **MacOSGaming**.

MacOSGaming does not bundle proprietary binaries or game assets. External runtimes are downloaded on-demand with user consent or detected from existing local user installations.

---

## 1. Wine / Wine-CX
- **Project:** Wine (Wine Is Not An Emulator)
- **Website:** https://www.winehq.org
- **License:** GNU Lesser General Public License (LGPL), version 2.1 or later
- **Notice:**  
  Wine is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.
- **Integration Mode:** External subprocess execution via command-line arguments and environment variables. Wine binaries are not embedded into the MacOSGaming Git repository.

---

## 2. DXMT
- **Project:** DXMT (DirectX 11 to Metal translation layer)
- **Author:** 3Shain
- **Repository:** https://github.com/3Shain/dxmt
- **License:** GNU Lesser General Public License v2.1 / MIT
- **Notice:**  
  DXMT provides clean-room translation from Direct3D 11 to Apple Metal. It is dynamically downloaded and configured in prefix directories upon user request.

---

## 3. DXVK & DXVK-macOS
- **Project:** DXVK
- **Author:** Philip Rebohle (doitsujin) and contributors
- **Repository:** https://github.com/doitsujin/dxvk
- **License:** Zlib / Libpng License
- **Notice:**  
  This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

---

## 4. MoltenVK
- **Project:** MoltenVK (Vulkan implementation layered over Metal)
- **Author:** The Khronos Group & The MoltenVK Authors
- **Repository:** https://github.com/KhronosGroup/MoltenVK
- **License:** Apache License, Version 2.0
- **Notice:**  
  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

---

## 5. Apple Game Porting Toolkit (D3DMetal)
- **Owner:** Apple Inc.
- **Website:** https://developer.apple.com
- **License:** Apple Game Porting Toolkit Evaluation License Agreement (Proprietary)
- **Strict Notice:**  
  **D3DMetal is proprietary software of Apple Inc. and is NOT included in, distributed with, or hosted by the MacOSGaming project.**  
  Developers wishing to evaluate D3DMetal must download it directly from Apple Developer Downloads in accordance with Apple's Evaluation License Agreement. MacOSGaming provides optional detection of locally installed evaluation tools solely on the user's personal machine.
