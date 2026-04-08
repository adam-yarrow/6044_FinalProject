function [Ness] = calcEffectiveSS(w,Ns)
    cv = var(w)/mean(w)^2;
    Ness = Ns/(1+cv);
end