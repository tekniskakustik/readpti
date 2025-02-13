


function y = getSize(filepath)

arguments (Input)
    filepath char {mustBeFile}
end
arguments (Output)
    y int64
end

if ispc()
    y = System.IO.FileInfo(filepath).Length;
else
    d = dir(filepath);
    y = d.bytes;
end

end


