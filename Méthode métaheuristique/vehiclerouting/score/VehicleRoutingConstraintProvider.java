package org.optaplanner.examples.vehiclerouting.score;

import org.optaplanner.core.api.score.buildin.hardsoftlong.HardSoftLongScore;
import org.optaplanner.core.api.score.stream.Constraint;
import org.optaplanner.core.api.score.stream.ConstraintFactory;
import org.optaplanner.core.api.score.stream.ConstraintProvider;
import org.optaplanner.core.api.score.stream.Joiners;
import org.optaplanner.examples.vehiclerouting.domain.Customer;
import org.optaplanner.examples.vehiclerouting.domain.Depot;
import org.optaplanner.examples.vehiclerouting.domain.Vehicle;
import org.optaplanner.examples.vehiclerouting.domain.location.Location;
import org.optaplanner.examples.vehiclerouting.domain.timewindowed.TimeWindowedCustomer;

import static org.optaplanner.core.api.score.stream.ConstraintCollectors.*;

public class VehicleRoutingConstraintProvider implements ConstraintProvider {

    @Override
    public Constraint[] defineConstraints(ConstraintFactory factory) {
        return new Constraint[] {
                vehicleCapacity(factory),
                distanceToPreviousStandstill(factory),
                distanceFromLastCustomerToDepot(factory),
                arrivalAfterDueTime(factory),
                //vehicleReturnToDepot(factory),
                //vehicleNotReturnToSameCustomer(factory)
        };
    }

    // ************************************************************************
    // Hard constraints
    // ************************************************************************


    //Contrainte 2/3/4/5
    protected Constraint vehicleCapacity(ConstraintFactory factory) {
        return factory.forEach(Customer.class)
                .filter(customer -> customer.getVehicle() != null)
                .groupBy(Customer::getVehicle, sum(Customer::getDemand))
                .filter((vehicle, demand) -> demand > vehicle.getCapacity())
                .penalizeLong(HardSoftLongScore.ONE_HARD,
                        (vehicle, demand) -> demand - vehicle.getCapacity())
                .asConstraint("vehicleCapacity");
    }

    // Contrainte n°8
    protected Constraint vehicleNotReturnToSameCustomer(ConstraintFactory factory) {
        return factory.forEach(Customer.class)
                .filter(customer -> customer.getNextCustomer() != null)
                .penalize(HardSoftLongScore.ONE_HARD, Customer::getDistanceFromNextStandstillHard)
                .asConstraint("vehicleNotReturnToSameCustomer");
    }

    // Contrainte n°7
    protected Constraint vehicleReturnToDepot(ConstraintFactory factory) {
        return factory.forEach(Customer.class)
                .filter(customer -> customer.getVehicle() != null)
                .penalize(HardSoftLongScore.ONE_HARD, Customer::vehicleHasDepot)
                .asConstraint("vehicleHasDepot");
    }

    // ************************************************************************
    // Soft constraints
    // ************************************************************************

    protected Constraint distanceToPreviousStandstill(ConstraintFactory factory) {
        return factory.forEach(Customer.class)
                .filter(customer -> customer.getVehicle() != null)
                .penalizeLong(HardSoftLongScore.ONE_SOFT,
                        Customer::getDistanceFromPreviousStandstill)
                .asConstraint("distanceToPreviousStandstill");
    }

    protected Constraint distanceFromLastCustomerToDepot(ConstraintFactory factory) {
        return factory.forEach(Customer.class)
                .filter(customer -> customer.getVehicle() != null && customer.getNextCustomer() == null)
                .penalizeLong(HardSoftLongScore.ONE_SOFT,
                        Customer::getDistanceToDepot)
                .asConstraint("distanceFromLastCustomerToDepot");
    }

    // ************************************************************************
    // TimeWindowed: additional hard constraints
    // ************************************************************************

    protected Constraint arrivalAfterDueTime(ConstraintFactory factory) {
        return factory.forEach(TimeWindowedCustomer.class)
                .filter(customer -> customer.getVehicle() != null && customer.getArrivalTime() > customer.getDueTime())
                .penalizeLong(HardSoftLongScore.ONE_HARD,
                        customer -> customer.getArrivalTime() - customer.getDueTime())
                .asConstraint("arrivalAfterDueTime");
    }



}
