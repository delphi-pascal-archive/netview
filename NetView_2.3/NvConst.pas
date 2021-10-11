unit NvConst;

interface

const
  INIT_KEY = '\Software\NetUtils\NetView\';
  NN_KEY = '\CLSID\{208D2C60-3AEA-1069-A2D7-08002B30309D}\shell\Scan with NetView\';
  MRU_KEY = 'FindResourceMRU\';
  SDefExt = '.txt';
  SFilter = 'Text Documents (*' + SDefExt + ')|*' + SDefExt + '|';
  SPosition        = 'Position';
  SWindowState     = 'WindowState';
  SResourceType    = 'Resource Type';
  SShowToolBar     = 'ShowToolBar';
  SShowResourceBar = 'ShowResourceBar';
  SShowStatusBar   = 'ShowStatusBar';
  SShowGridLines   = 'ShowGridLines';
  SShowHotTrack    = 'ShowHotTrack';
  SShowRowSelect   = 'ShowRowSelect';
  SMRUList         = 'MRUList';
  
  NetResNames: array [0..2] of string[15] = (
    'Computers',
    'Shared folders',
    'Shared printers');
  ColumnNames: array [0..4] of string[11] = (
    'Name',
    'Group',
    'Comment',
    'IP Address',
    'MAC Address');

resourcestring
  SWinSockErr = 'Could not initialize Winsock.';
  SProblemWithNA = 'Problem with network adapter.';
  SResetLanaErr = 'Reset Lana error.';
  SScanWithNetView = 'Scan with Net&View';
  SUpdating = 'Updating...';
  SLocalInet = 'Local intranet';
  SStatusText = '%d %s found';
  SResNotFound = 'Resource ''%s'' not found.';
  SPingDlgCaption = 'Ping %s';
  SInitErr = 'Error: Could not initialize icmp.dll.';
  SPinging = 'Pinging %s [%s] with %d bytes of data:'#13#10;
  SReqTimedOut = 'Request timed out.';
  SPacketTooBig = 'Packet needs to be fragmented.';
  SErrorCode = 'Error: %d.';
  SReply = 'Reply from %s: bytes=%d time%sms TTL=%d';
  SMsgDlgCaption = 'Message from %s';
  
implementation

end.
