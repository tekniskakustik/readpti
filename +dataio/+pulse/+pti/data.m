


classdef data < matlab.mixin.SetGet & matlab.mixin.Copyable

    properties
        ChannelInfo        dataio.pulse.pti.channel
        SampleFrequency    double
        NoChannels         int64
        DataType           char
        DataBitSize        int8
        FormatID           char
        Version            char
        Date               char
        Time               char
        TimeSignal         single % not in PTI file
        XML                struct % not in PTI file
    end

    properties (Hidden = true)
        HeaderVersion      int16 {mustBeNumericScalarOrEmpty}
        RECInfoSectionSize int64
        RECInfoSectionPos  int64
        OffsetStartSample  int64
        OffsetStopSample   int64
    end

    properties (Constant = true)
        DateFormat char = 'dd/mmm/yyyy' % not in PTI file
        TimeFormat char = 'HH:MM:SS:FFF' % not in PTI file
    end

end


