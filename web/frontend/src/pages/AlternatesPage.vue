<template>
  <trip-search
    :from-place="fromPlace"
    :to-place="toPlace"
    :current-mode="mode"
    :did-select-from-place="searchBoxDidSelectFromPlace"
    :did-select-to-place="searchBoxDidSelectToPlace"
    :did-swap-places="clickedSwap"
  />
  <div class="bottom-card bg-white" ref="bottomCard" v-if="error">
    <div class="search-error">
      <p>
        {{ errorText(error) }}
      </p>
      <div v-if="error.transit">
        <router-link
          :to="{ name: 'alternates', params: { mode: 'car', to, from } }"
          >{{ $t('try_driving_directions') }}</router-link
        >
      </div>
    </div>
  </div>
  <div class="bottom-card bg-white" ref="bottomCard" v-if="trips.length > 0">
    <q-list>
      <trip-list-item
        v-for="trip in trips"
        :click-handler="() => clickTrip(trip)"
        :active="$data.activeTrip === trip"
        :duration-formatted="trip.durationFormatted"
        :distance-formatted="trip.lengthFormatted"
        v-bind:key="JSON.stringify(trip)"
      >
        <component
          :is="componentForMode(trip.mode)"
          :trip="trip"
          :active="trip === activeTrip"
          :earliest-start="earliestStart"
          :latest-arrival="latestArrival"
        />
        <q-item-label>
          <q-btn
            style="margin-left: -6px"
            padding="6px"
            flat
            icon="directions"
            :label="$t('route_picker_show_route_details_btn')"
            size="sm"
            v-on:click="showTripSteps(trip)"
          />
        </q-item-label>
      </trip-list-item>
    </q-list>
  </div>
</template>
<style lang="scss">
.search-error {
  padding: 16px;
}
</style>

<script lang="ts">
import {
  destinationMarker,
  sourceMarker,
  getBaseMap,
  setBottomCardAllowance,
} from 'src/components/BaseMap.vue';
import { DistanceUnits } from 'src/utils/models';
import { Component, defineComponent, Ref, ref } from 'vue';
import Place, { PlaceStorage } from 'src/models/Place';
import { TravelMode } from 'src/utils/models';
import TripListItem from 'src/components/TripListItem.vue';
import TripSearch from 'src/components/TripSearch.vue';
import SingleModeListItem from 'src/components/SingleModeListItem.vue';
import MultiModalListItem from 'src/components/MultiModalListItem.vue';
import Trip, { fetchBestTrips, TripFetchError } from 'src/models/Trip';
import Itinerary, { ItineraryErrorCode } from 'src/models/Itinerary';
import { RouteErrorCode } from 'src/models/Route';

let toPlace: Ref<Place | undefined> = ref(undefined);
let fromPlace: Ref<Place | undefined> = ref(undefined);

export default defineComponent({
  name: 'AlternatesPage',
  props: {
    mode: {
      type: String as () => TravelMode,
      required: true,
    },
    to: String,
    from: String,
  },
  data: function (): {
    trips: Trip[];
    error?: TripFetchError;
    activeTrip: Trip | undefined;
    // only used by transit
    earliestStart: number;
    latestArrival: number;
  } {
    return {
      trips: [],
      error: undefined,
      activeTrip: undefined,
      earliestStart: 0,
      latestArrival: 0,
    };
  },
  components: { TripListItem, TripSearch },
  methods: {
    errorText(error: TripFetchError): string {
      if (error.transit) {
        switch (error.itineraryError.errorCode) {
          case ItineraryErrorCode.SourceOutsideBounds:
            return this.$t('transit_area_not_supported_for_source');
          case ItineraryErrorCode.DestinationOutsideBounds:
            return this.$t('transit_area_not_supported_for_destination');
          case ItineraryErrorCode.Other:
            return this.$t('transit_trip_error_unknown');
        }
      } else {
        switch (error.routeError.errorCode) {
          case RouteErrorCode.UnsupportedArea:
            return this.$t('routing_area_not_supported');
          case RouteErrorCode.Other:
            return this.$t('routing_error_unknown');
        }
      }
    },
    componentForMode(mode: TravelMode): Component {
      switch (mode) {
        case TravelMode.Walk:
        case TravelMode.Bike:
        case TravelMode.Drive:
          return SingleModeListItem;
        case TravelMode.Transit:
          return MultiModalListItem;
      }
    },
    clickTrip(trip: Trip) {
      this.$data.activeTrip = trip;
      let index = this.$data.trips.indexOf(trip);
      if (index !== -1) {
        this.renderTrips(index);
      }
    },
    searchBoxDidSelectFromPlace(place?: Place) {
      this.fromPlace = place;
      this.rewriteUrl();
    },
    searchBoxDidSelectToPlace(place?: Place) {
      this.toPlace = place;
      this.rewriteUrl();
    },
    showTripSteps(trip: Trip) {
      let index = this.$data.trips.indexOf(trip);
      if (index !== -1 && this.to && this.from) {
        this.$router.push(
          `/directions/${this.mode}/${encodeURIComponent(
            this.to
          )}/${encodeURIComponent(this.from)}/${index}`
        );
      }
    },
    clickedSwap(newFromValue?: Place, newToValue?: Place) {
      fromPlace.value = newFromValue;
      toPlace.value = newToValue;
      this.rewriteUrl();
    },
    rewriteUrl: async function () {
      if (!fromPlace.value && !toPlace.value) {
        this.$router.push('/');
        return;
      }

      const fromEncoded = fromPlace.value?.urlEncodedId() ?? '_';
      const toEncoded = toPlace.value?.urlEncodedId() ?? '_';
      this.$router.push(`/directions/${this.mode}/${toEncoded}/${fromEncoded}`);
      await this.updateTrips();
    },

    async updateTrips(): Promise<void> {
      let map = getBaseMap();
      if (!map) {
        console.error('map was not set');
        return;
      }

      map.removeAllLayers();
      map.removeAllMarkers();
      if (fromPlace.value && toPlace.value) {
        const result = await fetchBestTrips(
          fromPlace.value.point,
          toPlace.value.point,
          this.mode,
          fromPlace.value.preferredDistanceUnits() ?? DistanceUnits.Kilometers
        );
        if (result.ok) {
          const trips = result.value;
          this.calculateTransitStats(trips);
          this.trips = trips;
          this.renderTrips(0);
        } else {
          this.trips = [];
          this.error = result.error;
        }
      }

      if (fromPlace.value) {
        map.pushMarker(
          'source_marker',
          sourceMarker().setLngLat(fromPlace.value.point)
        );
      }

      if (toPlace.value) {
        map.pushMarker(
          'destination_marker',
          destinationMarker().setLngLat(toPlace.value.point)
        );
      }
    },
    renderTrips(selectedIdx: number) {
      console.assert(this.trips.length > 0);
      const trips: Trip[] = this.trips;
      const map = getBaseMap();
      if (!map) {
        console.error('basemap was unexpectedly empty');
        return;
      }
      this.$data.trips = trips;
      this.activeTrip = trips[selectedIdx];

      const unselectedLayerName = (tripIdx: number, legIdx: number) =>
        `alternate_${this.mode}_${tripIdx}.${legIdx}_unselected`;
      const selectedLayerName = (tripIdx: number, legIdx: number) =>
        `alternate_${this.mode}_${tripIdx}.${legIdx}_selected`;

      for (let tripIdx = 0; tripIdx < trips.length; tripIdx++) {
        const trip = trips[tripIdx];
        for (let legIdx = 0; legIdx < trip.legs.length; legIdx++) {
          const leg = trip.legs[legIdx];
          if (tripIdx == selectedIdx) {
            if (map.hasLayer(unselectedLayerName(tripIdx, legIdx))) {
              map.removeLayer(unselectedLayerName(tripIdx, legIdx));
            }
            continue;
          }

          if (map.hasLayer(selectedLayerName(tripIdx, legIdx))) {
            map.removeLayer(selectedLayerName(tripIdx, legIdx));
          }

          if (map.hasLayer(unselectedLayerName(tripIdx, legIdx))) {
            continue;
          }

          map.pushTripLayer(
            unselectedLayerName(tripIdx, legIdx),
            leg.geometry(),
            leg.paintStyle(false)
          );
        }
      }

      // Add selected trip last to be sure it's on top of the unselected trips
      const selectedTrip = trips[selectedIdx];
      for (let legIdx = 0; legIdx < selectedTrip.legs.length; legIdx++) {
        const leg = selectedTrip.legs[legIdx];
        if (!map.hasLayer(selectedLayerName(selectedIdx, legIdx))) {
          map.pushTripLayer(
            selectedLayerName(selectedIdx, legIdx),
            leg.geometry(),
            leg.paintStyle(true)
          );
        }
      }
      setTimeout(async () => {
        this.resizeMap();
      });
      getBaseMap()?.fitBounds(selectedTrip.bounds);
    },
    resizeMap() {
      if (this.$refs.bottomCard && this.$refs.bottomCard) {
        setBottomCardAllowance(
          (this.$refs.bottomCard as HTMLDivElement).offsetHeight
        );
      } else {
        setBottomCardAllowance(0);
      }
    },
    calculateTransitStats(trips: Trip[]) {
      this.$data.earliestStart = Number.MAX_SAFE_INTEGER;
      this.$data.latestArrival = 0;
      // terrible hack.
      if (this.mode != TravelMode.Transit) {
        return;
      }

      let itineraries: Itinerary[] = trips as Itinerary[];

      for (var index = 0; index < itineraries.length; index++) {
        this.$data.earliestStart = Math.min(
          this.$data.earliestStart,
          itineraries[index].startTime
        );
        this.$data.latestArrival = Math.max(
          this.$data.latestArrival,
          itineraries[index].endTime
        );
      }
    },
  },
  watch: {
    mode: async function (): Promise<void> {
      await this.updateTrips();
      this.resizeMap();
    },
  },
  unmounted: function () {
    getBaseMap()?.removeLayersExcept([]);
  },
  mounted: async function () {
    if (this.to != '_') {
      toPlace.value = await PlaceStorage.fetchFromSerializedId(
        this.to as string
      );
    }
    if (this.from != '_') {
      fromPlace.value = await PlaceStorage.fetchFromSerializedId(
        this.from as string
      );
    }

    await this.rewriteUrl();
    this.resizeMap();
  },
  setup: function () {
    return {
      toPlace,
      fromPlace,
    };
  },
});
</script>
