import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { TopBarComponent } from './top-bar/top-bar.component';
import { CurrentTemperatureComponent } from './current-temperature/current-temperature.component';
import { TemperatureHistoryComponent } from './temperature-history/temperature-history.component';
import { ThresholdViolationHistoryComponent } from './threshold-violation-history/threshold-violation-history.component';
import { ProfileComponent } from './profile/profile.component';
import { MessagesComponent } from './messages/messages.component';

@NgModule({
  declarations: [
    AppComponent,
    TopBarComponent,
    CurrentTemperatureComponent,
    TemperatureHistoryComponent,
    ThresholdViolationHistoryComponent,
    ProfileComponent,
    MessagesComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    HttpClientModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
