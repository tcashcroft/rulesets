import { Injectable } from '@angular/core';
import { Profile } from './profile';
import { Observable, of, throwError } from 'rxjs';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { catchError } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class ProfileService {

  private eci = 'ckld69zv4000j1ei074l78t6z';
  private rid = 'com.tcashcroft.sensor_profile';
  private eid = 'none';
  private domain = 'sensor';
  private type = 'profile_updated';
  private profileFunction = 'current_profile';
  private getProfileUrl = ''.concat('http://localhost:3000/sky/cloud/', this.eci, '/', this.rid, '/', this.profileFunction);
  private raiseProfileUpdateEventUrl = ''.concat('http://localhost:3000/sky/event/', this.eci, '/', this.eid, '/', this.domain, '/', this.type);
  private target: string;

  constructor(private http: HttpClient) {
  }

  getProfile(): Observable<Profile> {
    return this.http.get<Profile>(this.getProfileUrl);
  }

  updateProfile(newProfile: Profile): void {
    this.target = this.raiseProfileUpdateEventUrl.concat("?location=", encodeURIComponent(newProfile.location), "&name=", encodeURIComponent(newProfile.name), "&threshold=", encodeURIComponent(newProfile.threshold), "&targetPhoneNumber=", encodeURIComponent(newProfile.targetPhoneNumber));
    this.http.post<string>(this.target, null).pipe(
      catchError(this.handleError)
    ).subscribe(val => console.log(val)); 
  }

  private handleError(error: HttpErrorResponse) {
  if (error.error instanceof ErrorEvent) {
    // A client-side or network error occurred. Handle it accordingly.
    console.error('An error occurred:', error.error.message);
  } else {
    // The backend returned an unsuccessful response code.
    // The response body may contain clues as to what went wrong.
    console.error(
      `Backend returned code ${error.status}, ` +
      `body was: ${error.error}`);
  }
  // Return an observable with a user-facing error message.
  return throwError(
    'Something bad happened; please try again later.');
  }
}
