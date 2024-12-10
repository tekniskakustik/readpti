# Read B&amp;K Pulse PTI files in Matlab
## Examples:
#### Read file, using PTI structure:
[success, S] = dataio.pulse.pti.read(filepath);
#### Read and convert file, according to the [Tamara data specification](https://www.tamara.app/tamaraFileSpecification.pdf):
[success, S] = dataio.pulse.pti.import(filepath);
\
\
\
License: BSD 3-Clause, see LICENSE for details
\
\
Copyright (c) 2024, NVH Group AB. All rights reserved.
\
\
[![View read B&K PTI files on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://mathworks.com/matlabcentral/fileexchange/177264-read-pulse-pti-files)
