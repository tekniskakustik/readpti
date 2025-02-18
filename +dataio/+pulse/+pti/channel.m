


classdef channel < matlab.mixin.SetGet & matlab.mixin.Copyable

    properties
        SignalName       char
        OrgSignalName    char
        CorrectionFactor double = 1
        Offset           double = 0
        OverloadRatio    double = 0
        Unit             char
        UseCorrection    logical = false
        SampleFrequency  double
        Point            int64   = 0
        Index            int64 % not in PTI file
    end

end


