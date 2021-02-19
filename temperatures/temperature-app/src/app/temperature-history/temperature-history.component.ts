import { Component, OnInit } from '@angular/core';
import { Temperature } from '../temperature';
import { TemperatureService } from '../temperature.service';
import { MessageService } from '../message.service';

@Component({
  selector: 'app-temperature-history',
  templateUrl: './temperature-history.component.html',
  styleUrls: ['./temperature-history.component.css']
})
export class TemperatureHistoryComponent implements OnInit {

  history: Temperature[];
  currentTemperature: Temperature;

  constructor(private temperatureService: TemperatureService, private messageService: MessageService) { }

  ngOnInit(): void {
    this.getTemperatures();
    this.getCurrentTemperature();
  }

  getTemperatures(): void {
    this.messageService.add("Getting temperatures");
    this.temperatureService.getTemperatures().subscribe(temperatures => {
	    this.history = temperatures.reverse();
    }
						       );
  }

  getCurrentTemperature(): void {
    this.messageService.add("Getting current temperature");
    this.temperatureService.getCurrentTemperature().subscribe(currentTemperature => this.currentTemperature = currentTemperature);
  }

}
