# reference/

Working reference material used to build and verify `matlab/+noiseanalyzer/`. Two different
provenances, handled differently:

## `*.py` files — python-acoustics (BSD-3-Clause)

Pulled from [python-acoustics/python-acoustics](https://github.com/python-acoustics/python-acoustics)
(`acoustics/standards/`), archived/read-only since 2024-02-07 but usable under its BSD-3-Clause
license. These are the analytical formulas the standards define (A/C-weighting, octave-band math,
atmospheric absorption), used as a cross-check while porting the MATLAB implementation — not
copied wholesale, and not all bug-free (see `CLAUDE.md` for one actual bug found and avoided).

## ISO 9613-2:1996 — not redistributed here

The full ISO 9613-2:1996 standard text is **not** in this repository, deliberately: ISO's own
copyright notice on the document reads *"© ISO 1996. All rights reserved. Unless otherwise
specified, no part of this publication may be reproduced or utilized in any form or by any means,
electronic or mechanical, including photocopying and microfilm, without permission in writing from
the publisher."* Redistributing the scan or its full extracted text would violate that.

What **is** here is `iso_9613_2_1996_equations.md` — a from-scratch summary in our own words,
citing equation numbers so the formulas can be located in the standard by anyone who has a copy,
with the underlying mathematical formulas themselves included (formulas/methods are generally not
copyrightable subject matter, only ISO's specific expression/text of the document is). If you need
the standard itself, purchase it from [iso.org](https://www.iso.org/standard/20649.html) (1996
edition) or the current [2024 edition](https://www.iso.org/standard/74047.html).
