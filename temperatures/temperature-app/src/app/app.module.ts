import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule} from '@angular/forms';
import { RouterModule } from '@angular/router';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { TopBarComponent } from './top-bar/top-bar.component';
import { CurrentTemperatureComponent } from './current-temperature/current-temperature.component';
import { TemperatureHistoryComponent } from './temperature-history/temperature-history.component';
import { ThresholdViolationHistoryComponent } from './threshold-violation-history/threshold-violation-history.component';
import { ProfileComponent } from './profile/profile.component';
import { MessagesComponent } from './messages/messages.component';
import { LandingComponent } from './landing/landing.component';

@NgModule({
  declarations: [
    AppComponent,
    TopBarComponent,
    CurrentTemperatureComponent,
    TemperatureHistoryComponent,
    ThresholdViolationHistoryComponent,
    ProfileComponent,
    MessagesComponent,
    LandingComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    HttpClientModule,
    FormsModule,
    RouterModule.forRoot([
      {path: 'profile', component: ProfileComponent},
      {path: 'landing', component: LandingComponent},
      {path: '', redirectTo: '/landing', pathMatch: 'full'}
    ])
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
