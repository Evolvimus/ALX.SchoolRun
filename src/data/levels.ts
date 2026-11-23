// Level als Textkarte (1 Zeichen = 1 Kachel à 45 px, 12 Zeilen).
// #=Boden  ==Plattform  c=Münze  B=Kiste  ^=Stacheln  e=Papierflieger  P=Start  F=Ziel
export interface Level { id: string; name: string; map: string[]; }

export const LEVELS: Level[] = [{
  id: 'schulhof',
  name: 'Level 1 – Der Schulhof',
  map: [
    '                                                                                              ',
    '                                                                                              ',
    '                                            ccc                                               ',
    '                       ccc                 =====              c c c                           ',
    '                      =====                                  =======          ccc             ',
    '            ccc                     e                                        =====         F  ',
    '           =====            cc               cc        e                                      ',
    '  P                  c c          =====     ====                    cc   B             cc     ',
    '               B    =====                          B         cc     BB   BB   c c    ====     ',
    '########    #####  ######  ^^  ######  #####  ##########  ######  #######  #######  ##########',
    '########    #####  ######  ##  ######  #####  ##########  ######  #######  #######  ##########',
    '########    #####  ######  ##  ######  #####  ##########  ######  #######  #######  ##########',
  ],
}];
