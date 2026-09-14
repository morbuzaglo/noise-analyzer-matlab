function settings = parseSettingsText(text)
%PARSESETTINGSTEXT Parse the plain-text key=value settings format (see defaultSettingsText) into
%   a struct of string fields. Blank lines and lines starting with '#' are ignored. Unrecognized
%   keys are kept as-is (harmless), so the format is forward-compatible.
arguments
    text (1,1) string
end
settings = struct();
lines = splitlines(text);
for i = 1:numel(lines)
    line = strtrim(lines(i));
    if line == "" || startsWith(line, "#")
        continue
    end
    parts = split(line, "=");
    if numel(parts) < 2
        continue
    end
    key = strtrim(parts(1));
    value = strtrim(join(parts(2:end), "="));
    settings.(matlab.lang.makeValidName(key)) = value;
end
end
