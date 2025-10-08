


function [l, errorMsg] = import(filepath, options)

arguments (Input)
    filepath               char    {mustBeFile}
    options.IgnoreXMLError logical              = false
end

arguments (Output)
    l struct
    errorMsg char
end


try
    [success, S] = dataio.pulse.pti.read(filepath, IgnoreXMLError =  options.IgnoreXMLError);
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
    'chNames',             [], ...
    'chUnits',             [], ...
    'chSensitivityString', [], ...
    'fs',                  S.SampleFrequency, ...
    'internal',            struct('pulse', []), ...
    'numberOfChannels',    S.NoChannels, ...
    'timeFormat',          'yyyy-mm-dd - HH:MM:SS');

Info.time    = datestr(datevec([S.Date, S.Time], [S.DateFormat, S.TimeFormat]), Info.timeFormat); %#ok<DATST>
Info.chNames = {S.ChannelInfo.SignalName};
% TODO: add DOF to chNames
Info.chUnits = {S.ChannelInfo.Unit};
Info.chSensitivityString = repmat({char.empty()}, 1, S.NoChannels);

Info.internal.pulse.pti.XML = S.XML;

ch_idx = 0;
for count = 1:numel(S.XML.Signals.Signal)
    if strcmpi(S.XML.Signals.Signal(count).Recorded, 'true')
        ch_idx  = ch_idx + 1;
        unitstr = char(S.XML.Signals.Signal(count).CalibrationSensitivity.UnitAttribute);
        K       = S.XML.Signals.Signal(count).CalibrationSensitivity.Text * S.XML.Signals.Signal(count).CalibrationGain;
        offset  = S.XML.Signals.Signal(count).CalibrationOffset;
        if isstruct(offset)
            if isfield(offset, 'Text')
                K = K + offset.Text;
            end
        elseif isnumeric(offset) && isscalar(offset)
            K = K + offset;
        end
        if strcmpi(unitstr, 'V/pa')
            Info.chSensitivityString{ch_idx} = sprintf('%.8g mV/pa', K * 1e3);
        else
            Info.chSensitivityString{ch_idx} = sprintf(['%.8g ', unitstr], K);
        end
    end
    if ch_idx == S.NoChannels
        break
    end
end

l = struct( ...
    'Info',       Info, ...
    'timeSignal', S.TimeSignal);

errorMsg = char.empty();


end


