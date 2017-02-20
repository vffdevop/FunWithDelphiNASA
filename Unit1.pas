unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, IPPeerClient,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  System.Rtti, System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.Bind.Components, Data.Bind.DBScope, FMX.Edit,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ExtCtrls, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, REST.Response.Adapter, REST.Client,
  Data.Bind.ObjectScope, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, FMX.Calendar, DateUtils, System.Actions,
  FMX.ActnList, FMX.Objects, FMX.MultiView, System.Threading, System.Sensors,
  System.Sensors.Components, FMX.ListBox, FMX.Grid.Style, Fmx.Bind.Grid,
  Data.Bind.Grid, FMX.ScrollBox, FMX.Grid, FMX.Ani, FMX.WebBrowser;

type
  TForm1 = class(TForm)
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    RESTResponseDataSetAdapter1: TRESTResponseDataSetAdapter;
    FDMemTable1: TFDMemTable;
    Edit1: TEdit;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    NetHTTPClient1: TNetHTTPClient;
    ActionList1: TActionList;
    GetImageAction: TAction;
    StyleBook1: TStyleBook;
    Calendar1: TCalendar;
    ToolBar1: TToolBar;
    Button1: TButton;
    Layout2: TLayout;
    Pie1: TPie;
    Pie2: TPie;
    WorkingAnimation: TAction;
    ListBox1: TListBox;
    ListBoxGroupHeader1: TListBoxGroupHeader;
    ListBoxItemLatitude: TListBoxItem;
    ListBoxItemLongitude: TListBoxItem;
    ListBoxHeader1: TListBoxHeader;
    Label1: TLabel;
    LocationSensor1: TLocationSensor;
    LinkControlToField1: TLinkControlToField;
    FDMemTable1date: TWideStringField;
    FDMemTable1explanation: TWideStringField;
    FDMemTable1hdurl: TWideStringField;
    FDMemTable1media_type: TWideStringField;
    FDMemTable1service_version: TWideStringField;
    FDMemTable1title: TWideStringField;
    FDMemTable1url: TWideStringField;
    Image1: TImage;
    BitmapAnimation1: TBitmapAnimation;
    WebBrowserGMaps: TWebBrowser;
    Layout3: TLayout;
    Layout4: TLayout;
    Layout5: TLayout;
    MultiView1: TMultiView;
    Button2: TButton;
    MultiView2: TMultiView;
    Layout1: TLayout;
    FloatAnimation1: TFloatAnimation;
    FloatAnimation2: TFloatAnimation;
    LabelDate: TLabel;
    LinkPropertyToFieldText: TLinkPropertyToField;
    ColorAnimation1: TColorAnimation;
    ListBoxHeader2: TListBoxHeader;
    Label2: TLabel;
    Switch2: TSwitch;
    Switch1: TSwitch;
    procedure FormCreate(Sender: TObject);
    procedure GetImageActionExecute(Sender: TObject);
    procedure Calendar1Change(Sender: TObject);
    procedure Pie1Click(Sender: TObject);
    procedure Pie2Click(Sender: TObject);
    procedure LocationSensor1LocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure Switch1Switch(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    BaseURL: String;
    BaseDate: String;
    Resource : string;
    AFirstImageStream: TMemoryStream;
    LocationDetected : boolean;
  end;
  const
   // get your key from https://api.nasa.gov/index.html#apply-for-an-api-key
   APIKey = 'DEMO_KEY';


var
  Form1: TForm1;

implementation
{$R *.fmx}

uses System.UIConsts;

procedure TForm1.Calendar1Change(Sender: TObject);
begin
  BaseDate := YearOf(Calendar1.DateTime).ToString + '-' + MonthOfTheYear(Calendar1.DateTime).ToString + '-' + DayOfTheMonth(Calendar1.DateTime).ToString;
  GetImageAction.Execute;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  BaseURL := 'https://api.nasa.gov/planetary/earth';
  Resource := 'imagery';
  ListBoxItemLatitude.ItemData.Detail  := '-';
  ListBoxItemLongitude.ItemData.Detail := '-';
  AFirstImageStream := Nil;
  LocationDetected  := false;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  BitmapAnimation1.Enabled := false;
  if Assigned(AFirstImageStream) then AFirstImageStream.Free;
  inherited;
end;

procedure TForm1.GetImageActionExecute(Sender: TObject);
var
AResponseStream: TMemoryStream;
URLString : string;
begin
  Application.ProcessMessages;
  RESTClient1.BaseURL   := BaseURL;
  RESTRequest1.Resource := Resource;
  ITask(TTask.Create(procedure
      begin
        TThread.Queue(nil,procedure
          begin
            RESTRequest1.Params.ParameterByName('api_key').Value := APIKey;
            // location parameters
            if LocationDetected then
            begin
              RESTRequest1.Params.ParameterByName('lat').Value  := ListBoxItemLatitude.ItemData.Detail;
              RESTRequest1.Params.ParameterByName('lon').Value  := ListBoxItemLongitude.ItemData.Detail;
            end
            else
            begin
              // Barcelona (Spain) City Center
              RESTRequest1.Params.ParameterByName('lat').Value  := '41.394';
              RESTRequest1.Params.ParameterByName('lon').Value  := '2.158';
            end;
            if BaseDate<>'' then
              RESTRequest1.Params.ParameterByName('date').Value := BaseDate;
            RESTRequest1.Execute;
            // check for first image
            if not Assigned(AFirstImageStream) then
            begin
              AFirstImageStream := TMemoryStream.Create;
              NetHTTPClient1.Get(Edit1.Text,AFirstImageStream);
              BitmapAnimation1.StartValue.LoadFromStream(AFirstImageStream);
              BitmapAnimation1.StopValue.LoadFromStream(AFirstImageStream);
              URLString := Format('https://maps.google.com/maps?q=%s,%s',
                                  [RESTRequest1.Params.ParameterByName('lat').Value,
                                   RESTRequest1.Params.ParameterByName('lon').Value]);
              WebBrowserGMaps.Navigate(URLString);
              WebBrowserGMaps.Visible := true;
            end
            else
            begin
              AResponseStream := TMemoryStream.Create;
              NetHTTPClient1.Get(Edit1.Text,AResponseStream);
              BitmapAnimation1.StopValue.LoadFromStream(AResponseStream);
              AResponseStream.Free;
            end;
            // animations
            BitmapAnimation1.Enabled := false;
            FloatAnimation1.Enabled  := false;
            FloatAnimation2.Enabled  := false;
            ColorAnimation1.Enabled  := false;

            BitmapAnimation1.Enabled := Switch2.IsChecked;
            FloatAnimation1.Enabled  := Switch2.IsChecked;
            FloatAnimation2.Enabled  := Switch2.IsChecked;
            ColorAnimation1.Enabled  := Switch2.IsChecked;
          end);
      end)).Start;
end;

procedure TForm1.LocationSensor1LocationChanged(Sender: TObject;
  const OldLocation, NewLocation: TLocationCoord2D);
var LDecSeparator : string;
    URLString     : string;
begin
  LocationDetected := true;
  LDecSeparator := FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator := '.';
  // show current location
  ListBoxItemLatitude.ItemData.Detail  := Format('%2.6f',[NewLocation.Latitude]);
  ListBoxItemLongitude.ItemData.Detail := Format('%2.6f',[NewLocation.Longitude]);
  // show map using Google Maps
  URLString := Format('https://maps.google.com/maps?q=%s,%s',
                      [Format('%2.6f',[NewLocation.Latitude]),
                       Format('%2.6f',[NewLocation.Longitude])]);
  WebBrowserGMaps.Navigate(URLString);
  WebBrowserGMaps.Visible := true;
  // deactive sensor
  LocationSensor1.Active := false;
end;

procedure TForm1.Pie1Click(Sender: TObject);
begin
Calendar1.Date := Calendar1.Date-15;
end;

procedure TForm1.Pie2Click(Sender: TObject);
begin
if (Calendar1.Date+1)>Now then Exit;
Calendar1.Date := Calendar1.Date+15;
end;

procedure TForm1.Switch1Switch(Sender: TObject);
begin
  LocationSensor1.Active := Switch1.IsChecked;
  if not LocationSensor1.Active then
  begin
    ListBoxItemLatitude.ItemData.Detail  := '-';
    ListBoxItemLongitude.ItemData.Detail := '-';
  end;
end;

end.
