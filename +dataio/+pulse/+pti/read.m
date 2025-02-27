


function [success, y] = read(filepath, options)

arguments (Input)
    filepath           char    {mustBeFile}
    options.HeaderOnly logical              = false
end

arguments (Output)
    success logical
    y
end


fid = fopen(filepath, 'r', 'l');
if fid < 0 % failed to open file
    success = false;
    y = 'Failed to open file.';
    return
end


% read first line, if not ";" -> fail
str = fgets(fid, 4);
if ~strncmpi(str, 'BKSU', 4)
    fclose(fid);
    success = false;
    y = 'Failed to read pre-header, file is not a B&K Pulse PTI file?';
    return
end


HEADER_DONE     = false;
CURRENT_SECTION = int8(0); % 0 = init, 1 = general section, 2 = channel information


y = dataio.pulse.pti.data(); % get empty data object


while ~HEADER_DONE
    str = fgetl(fid);

    if strcmpi(str, '[SETUP START]')
        CURRENT_SECTION = int8(1);
        continue

    elseif strcmpi(str, '[SETUP STOP]')
        HEADER_DONE     = true;
        continue

    elseif startsWith(str, '[Channel')
        CURRENT_SECTION = int8(2);
        CURRENT_CHANNEL = int16(str2double(strtrim(strrep(str(9:end), ']', char.empty))));
        y.ChannelInfo(CURRENT_CHANNEL)       = dataio.pulse.pti.channel();
        y.ChannelInfo(CURRENT_CHANNEL).Index = CURRENT_CHANNEL;
        continue

    end

    switch CURRENT_SECTION
        case 1 % general info
            S = y;

        case 2 % channel info
            S = y.ChannelInfo(CURRENT_CHANNEL);

        otherwise
            continue

    end

    C = extractString(str);
    if numel(C) ~= 2
        continue
    end

    if isprop(S, C{1})
        if isnumeric(S.(C{1}))
            S.(C{1}) = str2double(strrep(C{2}, ',', '.'));

        elseif ischar(S.(C{1}))
            S.(C{1}) = C{2};

        end
    end
end


if options.HeaderOnly
    fclose(fid);
    success = true;
    return
end


temp_filepath = tempname();
fid_temp = fopen(temp_filepath, 'W');
if fid_temp < 0
    fclose(fid);
    success = false;
    return
end


fseek(fid, y.RECInfoSectionPos, -1);
str = fread(fid, y.RECInfoSectionSize, 'uint8=>uint8');
if numel(str) > 6 && isequal(str(1:6), [239; 187; 191; 60; 63; 120])
    str(1:3) = [];
end
fwrite(fid_temp, str, 'uint8');
fclose(fid_temp);
F_XML = parfeval(backgroundPool, @readstruct, 1, temp_filepath, 'FileType', 'xml');


INDEX_DATA_START = y.RECInfoSectionSize + y.RECInfoSectionPos + y.OffsetStartSample + 20;
status = fseek(fid, INDEX_DATA_START, -1);
if status ~= 0
    fclose(fid);
    success = false;
    return
end


num_val = y.OffsetStopSample - y.OffsetStartSample;
data    = zeros(num_val, y.NoChannels, 'single');


if ver2num(y.Version) >= 2 % unknown if there are more breaking changes with different versions
    val_per_block = 1024;
else
    val_per_block = 2048;
end
num_blocks = num_val/val_per_block;

if machine.getSize(filepath) < INDEX_DATA_START + num_val*y.NoChannels*4 % 16-bit pti-file | not any known metadata indicate bitdepth correctly :(
    datatype = '16bit';
else
    datatype = '24bit';
end


try
    if strcmpi(datatype, '16bit')
        K            = [y.ChannelInfo.CorrectionFactor];
        block_offset = 8; % skip first 16 bytes
        precision    = 'int16=>double';

    else % 24-bit pti-file
        K            = [y.ChannelInfo.CorrectionFactor] / (2^16-1);
        block_offset = 4; % skip first 16 bytes
        precision    = 'int32=>double';

    end

    for count = 1:num_blocks
        if count < num_blocks
            vals_to_read = val_per_block;
        else
            vals_to_read = mod(num_val, val_per_block);
            if vals_to_read == 0
                vals_to_read = val_per_block;
            end
        end
        tmp = fread(fid, [vals_to_read + block_offset, y.NoChannels], precision);
        data(val_per_block*(count-1)+1:val_per_block*(count-1)+vals_to_read, :) = tmp((block_offset+1):end, :) .* K; % skip first 16 bytes
    end

    y.TimeSignal = data;

catch
    fclose(fid);
    success = false;
    return

end

fclose(fid);


try
    t = tic();
    while strcmpi(F_XML.State, 'running') && toc(t) < 2
        pause(0.05)
    end
    y.XML   = F_XML.fetchOutputs;
    success = true;
catch
    success = false;
end

delete(F_XML);
delete(temp_filepath);


end % end of main function



function y = extractString(str)

arguments (Output)
    y cell
end

y = strtrim(strsplit(str, '='));

end



function y = startsWith(str, pat, options)

arguments (Input)
    str char
    pat char
    options.IgnoreCase logical = true
end

arguments (Output)
    y logical
end

n = numel(pat);

if options.IgnoreCase
    y = strncmpi(str, pat, n);
else
    y = strncmp(str, pat, n);
end

end



function y = ver2num(str)

arguments (Input)
    str char
end

arguments (Output)
    y double
end

C = strsplit(str, '.');
y = str2double(strjoin(C(1:min(2:end)), '.'));

end


