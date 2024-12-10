


function [l, errorMsg] = import(filepath)

arguments
    filepath char {mustBeFile}
end


try
    [success, S] = dataio.pulse.pti.read(filepath);
catch err
    l = struct();
    errorMsg = err.message;
    return
end

if ~success
    l = struct();
    errorMsg = ['Failed to import "', filepath, '"'];
    return
end


Info = struct( ...
    'chNames', [], ...
    'chUnits', [], ...
    'chSensitivityString', [], ...
    'fs', S.SampleFrequency, ...
    'internal', struct('pulse', []), ...
    'numberOfChannels', S.NoChannels, ...
    'timeFormat', 'yyyy-mm-dd - HH:MM:SS');

Info.time = datestr(datevec([S.Date, S.Time], [S.DateFormat, S.TimeFormat]), Info.timeFormat); %#ok<DATST>

Info.chNames = {S.ChannelInfo.SignalName};
Info.chUnits = {S.ChannelInfo.Unit};
Info.chSensitivityString = repmat({char.empty()}, 1, S.NoChannels);

Info.internal.pulse.configuration = S.XML;

ch_idx = 0;
for count = 1:numel(S.XML.Signals.Signal)
    if strcmpi(S.XML.Signals.Signal(count).Recorded, 'true')
        ch_idx = ch_idx + 1;
        unitstr = char(S.XML.Signals.Signal(count).CalibrationSensitivity.UnitAttribute);
        if strcmpi(unitstr, 'V/pa')
            Info.chSensitivityString{ch_idx} = sprintf('%.5g mV/pa', S.XML.Signals.Signal(count).CalibrationSensitivity.Text * 1e3);
        else
            Info.chSensitivityString{ch_idx} = sprintf(['%.5g ', unitstr], S.XML.Signals.Signal(count).CalibrationSensitivity.Text);
        end
    end
    if ch_idx == S.NoChannels
        break
    end
end

l = struct( ...
    'Info', Info, ...
    'timeSignal', S.TimeSignal);

errorMsg = char.empty();


end


