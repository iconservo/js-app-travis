import { Component,ViewChild } from '@angular/core';
import { NavController, Platform, Content } from 'ionic-angular';
import { NgZone } from "@angular/core";
import {StatusBar} from "@ionic-native/status-bar";

declare let device:any;
declare let ble:any;
declare let FileTransfer:any;
declare let cordova:any;
declare let PushNotification:any;
//declare var Camera:any;

@Component({
  selector: 'page-home',
  //templateUrl: 'home.html'
  template:
  '<ion-header><ion-navbar><ion-title>Home</ion-title></ion-navbar></ion-header>'+
  '<ion-content padding><ion-list>' +
  '<ion-item *ngFor="let item of items">{{item}}</ion-item>' +
  '</ion-list></ion-content>'
})
export class HomePage {
  @ViewChild(Content) content: Content;
  items = [];

  ready: boolean = false;

  constructor(private platform: Platform, private zone: NgZone, private statusbar: StatusBar, public navCtrl: NavController) {
    console.log("woof");
    this.zone = zone;
    this.statusbar = statusbar;
    this.platform.ready().then(()=>{
      console.log("platform ready from page constructor");
      this.ready = true;
      this.ionViewWillEnter();
    });
  }

  logmsg(message: string) {
    this.zone.run(() => {
      this.items.push(message);
    });
  }
  /*
  sideshow(that: HomePage) {
    (<any>navigator).splashscreen.show();
    setTimeout(function() {
      (<any>navigator).splashscreen.hide();
      setTimeout(function() {
        that.statusbar.hide();
        setTimeout(function() {
          that.statusbar.show();
          setTimeout(function(){
            cordova.plugins.Keyboard.show();
            setTimeout(function() {
              cordova.plugins.Keyboard.close();
            }, 1000);
          }, 1000);
        }, 1001);
      }, 1000);
    }, 500);
  }
  */

  ionViewWillEnter() {
    console.log("rendered-2!");
    if(!this.ready)
      return;
    this.items.length = 0;
    let that = this;

    that.logmsg('device.platform:' + device.platform);
    that.logmsg('device.model:' + device.model);

    cordova.getAppVersion.getVersionNumber(function (version) {
      that.logmsg('app version:' + version);
    });
    cordova.getAppVersion.getVersionCode(function (code) {
      that.logmsg('app versioncode:' + code);
    });
    cordova.getAppVersion.getAppName(function (name) {
      that.logmsg('app name:' + name);
    });

    let fileTransfer = new FileTransfer();
    fileTransfer.download(
      'https://now.httpbin.org',
      'cdvfile://localhost/temporary/time.json',
      function (entry) {
        console.log("Download complete:" + JSON.stringify(entry));
        that.logmsg('Filetransfer:OK');
      },
      function (error) {
        console.log("Download error:" + JSON.stringify(error));
        that.logmsg('Filetransfer:Error');
      });
    (<any>navigator).geolocation.getCurrentPosition(function (position) {
      that.logmsg('Nav lat:' + position.coords.latitude.toFixed(3) +
        ' lon:' + position.coords.longitude.toFixed(3));
    }, function (error) {
      that.logmsg('Error:' + error.message);
    }, { enableHighAccuracy: true } );

    ble.isEnabled(function() {
      that.logmsg('Bluetooth is enabled');
    },function() {
      that.logmsg('Bluetooth is *not* enabled');
    });
    that.logmsg('network connection:'+ (<any>navigator).connection.type);
    that.logmsg('screen orientation:' + (<any>window).screen.orientation.type);

    PushNotification.init({
      android: { senderID: "12345679" },
      ios: { badge: true }
    });

    PushNotification.hasPermission(function(data) {
      if (data.isEnabled) {
        that.logmsg('Push is enabled');
      } else {
        that.logmsg('Push not working!');
      }
    });
    //this.sideshow(that);
    /*
    (<any>navigator).camera.getPicture(
      function(uri){
        that.logmsg('Picture:' + JSON.stringify(uri) );
      }, function(error){
        that.logmsg('Camera err:' + JSON.stringify(error) );
      }, {
        destinationType: Camera.DestinationType.FILE_URI,
        sourceType: Camera.PictureSourceType.PHOTOLIBRARY,
      }
    );
    */

    console.log(cordova.file.applicationDirectory);
    (<any>window).resolveLocalFileSystemURL(cordova.file.applicationDirectory, (fileSystem) => {
      that.logmsg('filesystem ready');
      var reader = fileSystem.createReader();
      reader.readEntries((entries) => {
        for (let entry of entries) {
          if(entry.name === 'config.xml')
            that.logmsg('found app config.xml');
        }
      });
    })
    //var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
  }
}
