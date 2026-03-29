function closeHangingWaitbar()
    F = findall(0, 'type', 'figure', 'tag', 'TMWWaitbar');
    delete(F);
end