%%{
    machine test;
    
    action permitTmpl { tmplLevel > 0 }
    action forbidTmpl { tmplLevel == 0 }
    
    action templateStart {
        tmplLevel++;
    }

    action templateEnd {
        tmplLevel--;
    }
    
    main := |*
        NumericLiteral => onNumericLiteral;
        Template => onTemplate;
        
    *|;
    
    write data;
}%%

int main() {
    int act, cs, tmplLevel = 0;
    char *p = "``", *pe = p + strlen(p), *eof = pe, *ts, *te; 
    %%write init;
    %%write exec;
    return 0;
}