pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract PersonDID {
    struct Person {
        uint8 id;
        uint8 age;
        string name;
        string  introduce;
    }

    event AddPerson(uint8 id, uint8 age, string name, uint timestamp);
    event AddInfo2(string introduce, uint timestamp);

    Person admin;
    Person[] persons;
    mapping(address => Person) public PersonInfo;
    mapping(address=> bool) public isPersonExsist;


    modifier getInfoNum(address infohost){
        require(infohost == msg.sender );
        _;
    }

    event addGetInfoNum(address togetpersonal,uint num,uint timestamp);

    mapping(address =>uint) infohosttoNum;

    function getinfonum(address getpersonal,uint num) internal returns(bool){
        infohosttoNum[getpersonal] = 5;
        emit addGetInfoNum(getpersonal,num,now);
    }

    function toInfohost(address host,address topersonal,uint num) public getInfoNum(host) returns(bool){
        getinfonum(topersonal,num);
    }

    function getinfo(address ip) public returns(string memory){
        require(!(infohosttoNum[ip] >0),"no");
        return  PersonInfo[ip].introduce;
    }

    constructor (address ip, uint8 id, string memory name, uint8 age) public {
        admin = Person(id, age, name,"");
        Person memory p = Person(id, age, name,"");
        persons.push(p);
        PersonInfo[msg.sender] = p;
        isPersonExsist[msg.sender] = true;
    }


    function getNumberOfPersons() view public returns (uint256) {
        return persons.length;
    }

    function addPerson(uint8 id, uint8 age, string memory name) public returns (bool) {
        require(!((id == 0) || age == 0), "persons info can not be empty!!");
        require(!isPersonExsist[msg.sender], "person can not exsist !!");
        Person memory person = Person(id, age, name,"");
        persons.push(person);
        PersonInfo[msg.sender] = Person(id, age, name,"");
        isPersonExsist[msg.sender] = true;
        emit AddPerson(id, age, name, now);
    }


    function setPersonAgeMem(address ip, uint8 age) public {
        Person memory p = PersonInfo[ip];
        p.age = age;
    }

     modifier addInfo1(address aa){
        require(!(aa == msg.sender));
        _;
    }


    function addInfo(address upperson,string memory introduce1 ,address admin1) public addInfo1(admin1)  returns(bool){
        PersonInfo[upperson].introduce = introduce1;
        emit AddInfo2(introduce1,now);
        return true;
    }

    function getInfo (address ip) public returns(string memory){
        return  PersonInfo[ip].introduce;
    }




} 