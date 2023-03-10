-ifndef(ATSU_HRL).
-define(ATSU_HRL, true).

% Administrative-Territorial System
%    O — області та АРК
%    K — міста, що мають спеціальний статус (Київ та Севастополь)
%    P — райони в областях та в АРК
%    H — територіальні громади
%    M — міста
%    T — селища міського типу
%    C — села
%    X — селища
%    B — райони в містах
-type catatu() :: o | k | p | h | m | t | c | x | b.

% Unit
-record(atu, {
      id        = [] :: [] | binary(), %# id
      name      = [] :: [] | binary(), %# назва
      category  = [] :: [] | binary(), %# категорія O|K|P|H|M|T|C|X|B
      area      = [] :: [] | binary(), %# код області, АРК, міста
      region    = [] :: [] | binary(), %# код району
      community = [] :: [] | binary(), %# код територіальної громади
      locality  = [] :: [] | binary(), %# код населеного пункту
      district  = [] :: [] | binary(), %# код району в місті
      code      = [] :: [] | binary()  %# унікальний ідентифікатор об'єкту
    }).

% Address
-record('Addr', {
      id            = [] :: [] | binary(), %# guid
      parent_id     = [] :: [] | binary(), %# guid батьківської одиниці
      name          = [] :: [] | binary(), %# власна назва
      koatuu        = [] :: [] | binary(), %# коатуу ідентифікатор. застаріле
      katottg       = [] :: [] | binary(), %# катоттг ідентифікатор
      post_code     = [] :: [] | binary(), %# мусор
      ukr_post      = [] :: [] | binary(), %# мусор
      kind          = [] :: [] | number(), %# код типу об'єкту
      abbreviation  = [] :: [] | binary(), %# скорочення типу об'єкту (вул., пров.)
      loc_id        = [] :: [] | binary(), %# guid
      loc_name      = [] :: [] | binary(), %# повний тип об'єкту (вулиця, провулок)
      path          = [] :: [] | binary(), %# повна адреса
      house_numbers = [] :: [] | list()    %# номери будинків. нема номерів
  }).

-endif.
