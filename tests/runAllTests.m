function results = runAllTests()
%RUNALLTESTS Run the full noiseanalyzer test suite and assert success.
%   Adds the project's matlab/ folder to the path (if not already), runs every test in this
%   folder (and subfolders), and throws if any test fails -- so this can be used both
%   interactively and as a CI-style gate (`matlab -batch "tests.runAllTests"` equivalent when run
%   from the project root).
here = fileparts(mfilename('fullpath'));
projectRoot = fileparts(here);
addpath(fullfile(projectRoot, 'matlab'));

results = runtests(here, 'IncludeSubfolders', true);
assertSuccess(results);
end
