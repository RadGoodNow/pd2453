#!/system/bin/sh

originalCsvPath="mtk_em_public_private.csv"
newCsvPath="mtk_em_public_private_transposed.csv"

> "$newCsvPath"

awk '
BEGIN {
    currentCluster = "";
    currentWlType = "";
    dataBlock = "";
    headers = "index,capacity,freq,volt,dyn,eff,static,temp,dsu_freq";
    split(headers, headerArray, ",");
    isFirstLine = 1;
}
{
    gsub("\r", "", $0);
    if (isFirstLine) {
        print $0 >> "'"$newCsvPath"'";
        isFirstLine = 0;
    } else if ($0 ~ /^cluster:/) {
        if (currentWlType != "" || dataBlock != "") {
            printData();
            currentWlType = "";
            dataBlock = "";
        }
        currentCluster = $0;
    } else if ($0 ~ /^wl_type:/) {
        if (currentWlType != "" || dataBlock != "") {
            printData();
        }
        currentWlType = $0;
        dataBlock = "";
    } else if ($0 !~ /^index/) {
        dataBlock = dataBlock $0 "\n";
    }
}

END {
    if (currentWlType != "" || dataBlock != "") {
        printData();
    }
}

function printData() {
    print currentCluster >> "'"$newCsvPath"'";
    print currentWlType >> "'"$newCsvPath"'";
    
    split(dataBlock, lines, "\n");
    if (length(lines) > 1) {
        numFields = split(lines[1], fields, ",");
        for (i = 1; i <= numFields; i++) {
            line = headerArray[i];
            for (j = 1; j <= length(lines); j++) {
                if (lines[j] == "") continue;
                split(lines[j], values, ",");
                line = line "," values[i];
            }
            print line >> "'"$newCsvPath"'";
        }
    }
    print "" >> "'"$newCsvPath"'";
}
' "$originalCsvPath"

echo "Data has been transposed and saved to $newCsvPath."