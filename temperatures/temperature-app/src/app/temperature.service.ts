import { Injectable } from '@angular/core';
import { Temperature } from './temperature';
import {Observable, of, timer } from 'rxjs';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { MessageService } from './message.service';
import { map, switchMap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class TemperatureService {

  private eci = 'ckld69zv4000j1ei074l78t6z';
  private rid = 'com.tcashcroft.temperature_store';
  private temperaturesFunction = 'temperatures';
  private currentTemperatureFunction = 'current_temperature';
  private temperaturesUrl = ''.concat('http://localhost:3000/sky/cloud/', this.eci, '/', this.rid, '/', this.temperaturesFunction); 
  private currentTemperatureUrl = ''.concat('http://localhost:3000/sky/cloud/', this.eci, '/', this.rid, '/', this.currentTemperatureFunction); 

  private currentTemperature: Observable<Temperature>;
  private temperatures: Observable<Temperature[]>;

  constructor(private http: HttpClient, private messageService: MessageService) { 
    this.temperatures = timer(1, 10000).pipe(
	    switchMap(() => this.http.get<Temperature[]>(this.temperaturesUrl))
    );
    this.currentTemperature = timer(1, 10000).pipe(
	    switchMap(() => this.http.get<Temperature>(this.currentTemperatureUrl))
    );
  }

  getTemperatures(): Observable<Temperature[]> {
    //this.messageService.add(this.temperaturesUrl);
    //return this.http.get<Temperature[]>(this.temperaturesUrl); 
    return this.temperatures;
  }

  getCurrentTemperature(): Observable<Temperature> {
    //this.messageService.add(this.currentTemperatureUrl);
    //return this.http.get<Temperature>(this.currentTemperatureUrl);
    return this.currentTemperature;
  }
}
