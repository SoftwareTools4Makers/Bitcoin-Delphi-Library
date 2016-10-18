unit st4makers.BitCoin;

interface

uses
  Classes, IdHTTP, System.json;

const
  GenesisHashBlock =
    '000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f';

  LargestTransBlock =
    '000000000000048eafc216a4b55f5cf2400786925e01d611bcf7964465de13e9';

type
  TInfoRecord = record
    version: string;
    protocolversion: string;
    blocks: string;
    timeoffset: string;
    connections: string;
    proxy: string;
    difficulty: string;
    testnet: string;
    paytxfee: string;
    relayfee: string;
  end;

  TNetWorkInfoRecord = record
    version: string;
    subversion: string;
    protocolversion: string;
    localservices: string;
    localrelay: string;
    timeoffset: TDateTime;
    connections: string;
    relayfee: string;
    warnings: string;
  end;

  TBlock = class(TObject)
  public
    ajson: string;
    Hash, Prev, Next: string;
    merkleroot: string;
    transactions: tstringlist;
    time, mediantime: TDateTime;
    height: integer;

  end;

  TBCN = class(TComponent)
  strict private
    fOnReady: TNotifyEvent;

    aHTTP: TIdHTTP;
    JsonToSend: TStringStream;
    fJSON: TJsonobject;

    function post(const command: string): string;

  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;

    procedure Start;
    function GetResultFromJSON(const ajson: string): string;
    function GetBlockJSON(const aBlockHash: string): string;
    function GetBlockHash(const aBlockNumber: integer): string;
    function GetBlock(const aBlockHash: string): TBlock;
    function GetInfo: TInfoRecord;
    function GetDifficulty: string;
    function GetNetworkInfo: TNetWorkInfoRecord;
    function GetBlockCount: string;

    function GetRawTransaction(const atx: string): string;

    property OnReady: TNotifyEvent read fOnReady write fOnReady;
  end;

function GetGlobalBNC: TBCN;

implementation

uses
  System.SysUtils, forms, System.dateutils;

var
  aGlobalTBCN: TBCN;

function GetGlobalBNC: TBCN;
begin
  if aGlobalTBCN = nil then
  begin
    aGlobalTBCN := TBCN.Create(nil);
  end;

  result := aGlobalTBCN;
end;

constructor TBCN.Create(Owner: TComponent);
begin
  inherited;

  aHTTP := TIdHTTP.Create(self);
  aHTTP.Request.Password := 'test';
  aHTTP.Request.Username := 'test';
  aHTTP.Request.BasicAuthentication := true;

end;

destructor TBCN.Destroy;
begin
  aHTTP.free;

  inherited;
end;

function TBCN.GetBlockHash(const aBlockNumber: integer): string;
begin
  result := GetResultFromJSON
    (post(format
    ('{"jsonrpc": "1.0", "id":"BTCExposed", "method": "getblockhash", "params": [%d] }',
    [aBlockNumber])));
end;

function TBCN.GetBlock(const aBlockHash: string): TBlock;
var
  fJSON: TJsonobject;
  json: string;
  aa: tjsonvalue;
  tx: TJSONArray;
  en: TJSONArrayEnumerator;
begin
  json := post
    (format('{"jsonrpc": "1.0", "id":"BTCExposed", "method": "getblock", "params": ["%s"] }',
    [aBlockHash]));

  result := TBlock.Create;

  fJSON := TJsonobject.Create;
  if fJSON.Parse(BytesOf(json), 0) > 0 then
  begin
    result.ajson := json;
    aa := fJSON.GetValue('result');
    result.Hash := aa.GetValue<string>('hash');

    // genesis block doesnt have prev
    try
      result.Prev := aa.GetValue<string>('previousblockhash');
    except
      result.Prev := '';
    end;

    result.Next := aa.GetValue<string>('nextblockhash');
    result.merkleroot := aa.GetValue<string>('merkleroot');

    result.transactions := tstringlist.Create;
    tx := aa.GetValue<TJSONArray>('tx');
    en := tx.GetEnumerator;
    while en.MoveNext do
    begin
      result.transactions.Add(en.GetCurrent.ToString);
    end;

    result.height := aa.GetValue<Int64>('height');
    result.time := UnixToDateTime(aa.GetValue<Int64>('time'));
    result.mediantime := UnixToDateTime(aa.GetValue<Int64>('mediantime'));
  end;
  fJSON.free;

end;

function TBCN.GetBlockJSON(const aBlockHash: string): string;
begin
  result := post
    (format('{"jsonrpc": "1.0", "id":"BTCExposed", "method": "getblock", "params": ["%s"] }',
    [aBlockHash]));
end;

function TBCN.GetBlockCount: string;
begin
  result := GetResultFromJSON
    (post('{"jsonrpc": "1.0", "id":"BTCExposed", "method": "getblockcount", "params": [] }')
    );
end;

function TBCN.GetDifficulty: string;
begin
  result := post
    ('{"jsonrpc": "1.0", "id":"BTCExposed", "method": "getdifficulty", "params": [] }')
end;

function TBCN.GetInfo: TInfoRecord;
var
  ajson: string;
  aa: tjsonvalue;
begin
  ajson := post
    ('{"jsonrpc": "1.0", "id":"BTCExposed", "method": "getinfo", "params": [] }');

  fJSON := TJsonobject.Create;
  if fJSON.Parse(BytesOf(ajson), 0) > 0 then
  begin
    aa := fJSON.GetValue('result');
    result.version := aa.GetValue<string>('version');
    result.protocolversion := aa.GetValue<string>('protocolversion');
    result.blocks := aa.GetValue<string>('blocks');
    result.timeoffset := aa.GetValue<string>('timeoffset');
    result.connections := aa.GetValue<string>('connections');
    result.proxy := aa.GetValue<string>('proxy');
    result.difficulty := aa.GetValue<string>('difficulty');
    result.testnet := aa.GetValue<string>('testnet');
    result.paytxfee := aa.GetValue<string>('paytxfee');
    result.relayfee := aa.GetValue<string>('relayfee');
  end;

  fJSON.free;
end;

function TBCN.GetNetworkInfo: TNetWorkInfoRecord;
var
  ajson: string;
  aa: tjsonvalue;
begin
  ajson := post
    ('{"jsonrpc": "1.0", "id":"BTCExposed", "method": "getnetworkinfo", "params": [] }');

  fJSON := TJsonobject.Create;
  if fJSON.Parse(BytesOf(ajson), 0) > 0 then
  begin
    aa := fJSON.GetValue('result');
    result.version := aa.GetValue<string>('version');
    result.subversion := aa.GetValue<string>('subversion');
    result.protocolversion := aa.GetValue<string>('protocolversion');
    result.localservices := aa.GetValue<string>('localservices');
    result.localrelay := aa.GetValue<string>('localrelay');
    result.timeoffset := UnixToDateTime(aa.GetValue<Int64>('timeoffset'));
    result.connections := aa.GetValue<string>('connections');
    result.relayfee := aa.GetValue<string>('relayfee');
    result.warnings := aa.GetValue<string>('warnings');
  end;

  fJSON.free;
end;

function TBCN.GetResultFromJSON(const ajson: string): string;
begin
  fJSON := TJsonobject.Create;
  if fJSON.Parse(BytesOf(ajson), 0) > 0 then
    result := fJSON.GetValue<string>('result');
  fJSON.free;
end;

function TBCN.GetRawTransaction(const atx: string): string;
begin
  result := post
    (format('{"jsonrpc": "1.0", "id":"BTCExposed", "method": "getrawtransaction", "params": [%s,1] }',
    [atx]));
end;

function TBCN.post(const command: string): string;
begin
  JsonToSend := TStringStream.Create(command);

  aHTTP.Request.Password := 'test';
  aHTTP.Request.Username := 'test';
  aHTTP.Request.BasicAuthentication := true;

  try
    result := aHTTP.post('http://127.0.0.1:8332', JsonToSend);
  finally
    JsonToSend.free;
  end;
end;

procedure TBCN.Start;
var
  fReady: boolean;
begin
  fReady := false;
  while not fReady do
  begin
    try
      GetInfo;
      fReady := true;
      if assigned(fOnReady) then
        fOnReady(self);
    except
      Application.ProcessMessages;
    end;

  end;
end;

initialization

aGlobalTBCN := nil;

end.
