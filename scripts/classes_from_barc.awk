# parses applets and classes out of the output of barc -d x.mif

$1 ~/^ID0x5000_00001$/ { 
    data = substr($4,2);
    data = substr(data, 1, 8*int(length(data)/8));
    data = gensub(/(..)(..)(..)(..)/, "\\4\\3\\2\\1\n", "g", data);
    gsub(/00000000\n/,"",data);
    printf("%s", data);
};
$1 ~/^ID0x5000_00002$/ { 
    data = substr($4,2);
    data = substr(data, 1, 40*int(length(data)/40));
    printf("%s",gensub(/(..)(..)(..)(..)................................/, "\\4\\3\\2\\1\n", "g", data));
};
